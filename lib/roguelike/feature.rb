module Roguelike
  class Feature
    attr_reader :cells, :grid

    GRAVITIES = [:north, :south, :east, :west]

    ROTATIONS = {
      south: ->(x, y) { [x, -y] },
      west: ->(x, y) { [y, -x] },
      east: ->(x, y) { [-y, x] }
    }

    CELL_ATTRIBUTES = {
      wall: { symbol: '#', wall: true },
      floor: { symbol: '.', transparent: true },
      starting_location: { symbol: 's', start: true, transparent: true },
      door: { symbol: 'D', transparent: true }
    }

    def initialize
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

    def mergeable?(other_feature, x1, y1, x2, y2)
      other_feature.cells.each do |cell|
        x = cell.x - x2 + x1
        y = cell.y - y2 + y1
        cell = lookup(x, y)
        return false if cell && !cell.wall
      end
      true
    end

    def lookup(x, y)
      @grid[y][x]
    end

    # FIXME The code seems a little 'black magick'
    def available_junctions(force_gravity = nil)
      junctions = []
      @cells.each do |cell|
        next unless cell.wall

        neighbours = [:up, :down, :left, :right].map do |direction|
          lookup(*cell.coordinates.at(direction).to_a)
        end.compact

        next unless neighbours.size == 3

        gravities = force_gravity ? [force_gravity] : GRAVITIES

        gravities.each do |gravity|
          feature = Feature.new
          center = cell.clone
          feature.add_cell center, -center.x
          neighbours.each { |c| feature.add_cell c.clone, -c.x }
          feature.rotate gravity

          cell_1 = feature.lookup(*center.coordinates.at(:right))
          cell_2 = feature.lookup(*center.coordinates.at(:left))
          cell_3 = feature.lookup(*center.coordinates.at(:down))

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
      cell.symbol || '?'
    end

    def build(map)
      reset
      map.each_with_index do |row, y|
        row.split(//).each_with_index do |symbol, x|
          attributes = CELL_ATTRIBUTES.values.find { |attrs| attrs[:symbol] == symbol }
          next unless attributes
          add_cell Roguelike::Cell.new x, y, attributes
        end
      end
      self
    end

    def make_cell(type)
      raise ArgumentError, "Unknown cell type: #{type.inspect}" unless CELL_ATTRIBUTES.has_key?(type)
      Cell.new 0, 0, CELL_ATTRIBUTES[type]
    end

    def rotate(direction)
      return self if direction == :north
      rotation = ROTATIONS[direction]
      cells = @cells.dup
      reset
      cells.each do |cell|
        x, y = rotation.call cell.x, cell.y
        add_cell cell, x, y
      end
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

      if options[:junction]
        add_cell make_cell(options[:junction]), x1, y1
      end

      self
    end

    private

    def reset
      @cells = []
      @grid = Hash.new { |hash, key| hash[key] = {} }
    end
  end

  class SquareRoom < Feature
    def build(width, height)
      reset
      height.times do |y|
        width.times do |x|
          type = :floor
          type = :wall if x == 0 || y == 0 || x.next == width || y.next == height
          add_cell make_cell(type), x, y
        end
      end
      self
    end
  end

  class Corridor < SquareRoom
    def available_junctions(force_gravity)
      junctions = super(force_gravity)
      case force_gravity
      when :north
        other_junctions = super(:west) + super(:east)
        max_height = other_junctions.map{|j| j.y}.min
        junctions += other_junctions.find_all { |j| j.y == max_height }
      when :south
        other_junctions = super(:west) + super(:east)
        min_height = other_junctions.map{|j| j.y}.max
        junctions += other_junctions.find_all { |j| j.y == min_height }
      end
      junctions
    end
  end
end
