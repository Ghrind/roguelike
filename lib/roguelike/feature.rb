module Roguelike
  class Feature
    attr_reader :direction, :cells

    GRAVITIES = [:north, :south, :east, :west]

    ROTATIONS = {
      north_south: ->(x, y) { [x, -y] },
      north_west: ->(x, y) { [y, -x] },
      north_east: ->(x, y) { [-y, x] }
    }

    def initialize
      @direction = :north
      reset
    end

    def add_cell(cell, x = nil, y = nil)
      cell.x = x if x
      cell.y = y if y
      if previous_cell = lookup(cell.x, cell.y)
        @cells.delete previous_cell
      end
      @cells << cell
      @grid[cell.y][cell.x] = cell
    end

    def lookup(x, y)
      @grid[y][x]
    end

    # FIXME The code seems a little 'black magick'
    def available_junctions
      junctions = []
      @cells.each do |cell|
        next unless cell.wall

        neighbours = [
          lookup(cell.x + 1, cell.y),
          lookup(cell.x - 1, cell.y),
          lookup(cell.x, cell.y + 1),
          lookup(cell.x, cell.y - 1)
        ].compact

        next unless neighbours.size == 3

        GRAVITIES.each do |gravity|
          feature = Feature.new
          center = cell.dup
          feature.add_cell center, -center.x
          neighbours.each { |c| feature.add_cell c.dup, -c.x }
          feature.rotate gravity

          cell_1 = feature.lookup(center.x + 1, center.y)
          cell_2 = feature.lookup(center.x - 1, center.y)
          cell_3 = feature.lookup(center.x, center.y + 1)

          next unless cell_1 && cell_1.wall
          next unless cell_2 && cell_2.wall
          next unless cell_3 && !cell_3.wall

          cell.direction = gravity
          junctions << cell
          break
        end
      end
      junctions
    end

    def min_x
      @cells.map { |c| c.x }.min
    end

    def min_y
      @cells.map { |c| c.y }.min
    end

    def max_x
      @cells.map { |c| c.x }.max
    end

    def max_y
      @cells.map { |c| c.y }.max
    end

    def map_symbol(cell)
      return ' ' if cell.nil?
      return '#' if cell.wall
      '.'
    end

    def rotate(direction)
      return self if direction == @direction
      rotation = ROTATIONS[:"#{@direction}_#{direction}"]
      cells = @cells.dup
      reset
      cells.each do |cell|
        x, y = rotation.call cell.x, cell.y
        add_cell cell, x, y
      end
      @direction = direction
      self
    end

    def to_map
      map = []
      min_y.upto(max_y) do |y|
        row = ''
        min_x.upto(max_x) do |x|
          row << map_symbol(@grid[y][x])
        end
        map << row
      end
      map
    end

    def merge(other_feature, x1, y1, x2, y2, options = {})
      other_feature.cells.each do |cell|
        add_cell cell, cell.x - x2 + x1, cell.y - y2 + y1
      end

      cell = options[:junction]
      if cell
        add_cell cell, x1, y1
      end

      self
    end

    private

    def reset
      @cells = []
      @grid = Hash.new { |hash, key| hash[key] = {} }
    end
  end
end
