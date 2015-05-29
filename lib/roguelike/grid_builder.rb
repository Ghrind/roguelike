require_relative 'feature'

module Roguelike
  class GridBuilder
    class Room
      attr_reader :width, :height
      attr_accessor :top, :left
      attr_reader :cells

      def initialize(top, left, height, width)
        @width = width
        @height = height
        @top = top
        @left = left

        @cells = build_cells
      end

      private

      # Create all cells of the room.
      # Adds symbol and direction.
      def build_cells
        cells = []
        @height.times do |y|
          @width.times do |x|

            direction = cell_direction x, y
            wall = direction != :none

            cell = Cell.new x + @left - 1, y + @top - 1, direction: direction, wall: wall
            cells << cell
          end
        end
        cells
      end

      # Returns the direction of the cell at x, y.
      #
      # Direction can be one of: none, top, bottom, left, right, top_left,
      #  top_right, bottom_left, bottom_right.
      #
      # @param x [Integer] x position of the cell in the room.
      # @param y [Integer] y position of the cell in the room.
      #
      # @return [Symbol] Direction of the cell.
      def cell_direction(x, y)
        direction = []
        if y == 0
          direction << 'top'
        elsif y.next == @height
          direction << 'bottom'
        end
        if x == 0
          direction << 'left'
        elsif x.next == @width
          direction << 'right'
        end
        if direction.empty?
          direction << 'none'
        end
        direction.join('_').to_sym
      end
    end

    def initialize(options = {})
      @options = {
        height: 20,
        width: 20,
        iterations: 150,
        room_min_size: 6,
        room_max_size: 13
      }.merge(options)

      @grid = Grid.new
    end

    def generate
      # First we put a room at the center of the map
      last_room = add_room((@options[:width] + @options[:room_min_size]) / 2, (@options[:height] + @options[:room_min_size]) / 2, @options[:room_min_size], @options[:room_min_size])

      # Add the starting location in the room
      start_cell = last_room.cells.find_all{ |c| c.walkable? }.sample
      @grid.player = { x: start_cell.x, y: start_cell.y }

      # Main loop
      @options[:iterations].times do

        # Choose the new room's starting location (junction cell)
        case rand(3)
        when (0..1)
          # Attached to last room
          cell = last_room.cells.find_all{ |c| c.wall && %i[top bottom left right].include?(c.direction) }.sample
        else
          # Attached to a random room
          cell = @grid.all_cells.find_all{ |c| c.wall && %i[top bottom left right].include?(c.direction) }.sample
        end

        # These are the new room's dimensions
        a = rand(1 + @options[:room_max_size] - @options[:room_min_size]) + @options[:room_min_size]
        b = rand(1 + @options[:room_max_size] - @options[:room_min_size]) + @options[:room_min_size]

        # Make corridors
        if rand(3) == 0
          if rand(1) == 0
            a = 3
          else
            b = 3
          end
        end

        # Add the new room depending on the wall's direction
        new_room = case cell.direction
        when :top
          add_room cell.y - b + 2, cell.x, b, a
        when :bottom
          add_room cell.y + 1, cell.x, b, a
        when :left
          add_room cell.y, cell.x - b + 2, a, b
        when :right
          add_room cell.y, cell.x + 1, a, b
        else
          raise "unknown direction '#{cell[:direction]}'"
        end

        next unless new_room

        # Remove the wall at junction cell
        @grid.add_cell Cell.new(cell.x, cell.y, wall: false), true

        last_room = new_room
      end

      # Add exit in the last room
      end_cell = last_room.cells.find_all { |c| c.walkable? }.sample
      @grid.destination = end_cell

      @grid.prepare!
      @grid
    end

    # Is the cell available for another cell?
    # At building time, a cell is available if it is in the grid's boundaries and if takes place on an empty cell or a wall
    #
    # @param x [Fixnum] X position of the cell
    # @param y [Fixnum] Y position of the cell
    # @return [Boolean] Is the position on the grid free to be replaced by another cell.
    def cell_available?(x, y)
      return false if x >= @options[:width] || y >= @options[:height] || x < 0 || y < 0
      cell = @grid.lookup(y, x)
      cell.nil? || !!cell.wall
    end
    
    private

    # Add a room at given location
    # @return [Room,nil] The room if there is enough space, nil if the room cannot be placed.
    def add_room(top, left, height, width)
      room = Room.new top, left, height, width

      # Check if all cells can be added
      return false unless room.cells.all? { |c| cell_available? c.x, c.y }
    
      # Add cells to grid and cells list
      room.cells.each do |cell|
        @grid.add_cell cell, true
      end

      room
    end
  end
end
