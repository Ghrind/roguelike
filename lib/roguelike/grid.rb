require 'logger'
require_relative 'cell'
require_relative 'astar'
require_relative 'grid_builder'

module Roguelike
  # The grid knows everything that is contained in a level and knows how to find path between them.
  #
  # The x position of a cell is it which column it belongs.
  # The y position of a cell is it which row it belongs.
  class Grid
    # Error raised when looking up a position that doesn't exist.
    class PositionOutOfBoundError < ArgumentError
    end

    # Contains the cells organized by rows and columns
    attr_accessor :cells

    # Contains the cells in an array
    attr_accessor :all_cells

    # DEV These are dev/debug instance variables
    attr_accessor :player
    attr_accessor :path
    attr_accessor :stalkers
    attr_accessor :destination

    def initialize(map)
      @logger = Logger.new('log/logfile.log') # TODO Should not be hard coded
      @path = [] # DEV Path of the current player.

      @player = nil # DEV The player.
      @stalkers = [] # DEV The creatures chasing the player.
      @destination = nil # DEV Where the player is heading.

      generate_cells(map)
      assign_neighbours
    end

    def tick(command)
      return if command == 'system.none'

      start = lookup(@player[:y], @player[:x])

      if start != @destination
        @path = astar.find_path(start, @destination)
        if @path
          @player = { x: @path[1].x, y: @path[1].y }
        end
      end

      @stalkers.each do |s|
        start = lookup(s[:y], s[:x])
        dest = lookup(@player[:y], @player[:x])
        next if start == dest
        path = astar.find_path(start, dest)
        if path
          s[:x] = path[1].x
          s[:y] = path[1].y
        end
      end
    end

    # @param y [Fixnum] The index of the row.
    # @param x [Fixnum] The index of the column.
    # @return [Cell] The cell at desired position.
    # @raise PositionOutOfBoundError if there is no cell at desired position.
    def lookup(y,x)
      if @cells[y].nil? || @cells[y][x].nil?
        raise PositionOutOfBoundError, "There is no cell at x:#{x}, y:#{y}"
      end
      @cells[y][x]
    end

    private

    # Sets the neighbours of each cell of the grid.
    # This will be used by the A star pathfinding algorithm.
    def assign_neighbours
      @all_cells.each do |cell|

        x = cell.x
        y = cell.y

        rb = @cells[y].size-1

        if y > 0
          cell.neighbours.push @cells[y-1][x-1] if x > 0
          cell.neighbours.push @cells[y-1][x]
          cell.neighbours.push @cells[y-1][x+1] if x < rb
        end

        if x > 0
          cell.neighbours.push @cells[y][x-1]
        end

        if x < rb
          cell.neighbours.push @cells[y][x+1]
        end

        if y < @cells.size-1
          cell.neighbours.push @cells[y+1][x-1] if x > 0
          cell.neighbours.push @cells[y+1][x]
          cell.neighbours.push @cells[y+1][x+1] if x < rb
        end

        cell.neighbours.compact!
      end
    end

    # Creates all cells and creatures by reading the map.
    #
    # Currently, the available symbols are:
    #   - Walls: #
    #   - Destination: >
    #   - Stalkers: !
    #   - Player: @
    #   - Open floor: .
    def generate_cells(map)
      @cells = []

      (0...map.size).each do |y|
        @cells[y] = []
        next unless map[y]
        (0...map[y].size).each do |x|
          symbol = map[y] && map[y][x] || ' '
          case symbol
          when '!'
            cell = Cell.new x, y, false
            @cells[y][x] = cell
            @stalkers << { x: x, y: y }
          when '#'
            @cells[y][x] = Cell.new x, y, true
          when '.'
            @cells[y][x] = Cell.new x, y, false
          when '@'
            cell = Cell.new x, y, false
            @cells[y][x] = cell
            @player = { x: x, y: y }
          when '>'
            cell = Cell.new x, y, false
            @cells[y][x] = cell
            @destination = cell
          when ' '
            # do nothing
          end
        end
      end

      @all_cells = @cells.flatten.compact
    end

    def astar
      @_astar = AStar.new
    end
  end
end
