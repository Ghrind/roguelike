require_relative 'cell'
require_relative 'astar'
require_relative 'grid_builder'

module Roguelike
  # The grid knows everything that is contained in a level and knows how to find path between them.
  #
  # The x position of a cell is it which column it belongs.
  # The y position of a cell is it which row it belongs.
  class Grid
    # Error raised when trying to add a cell on top of another cell
    class CellNotAvailableError < ArgumentError
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

    def initialize
      @path = [] # DEV Path of the current player.

      @player = nil # DEV The player.
      @stalkers = [] # DEV The creatures chasing the player.
      @destination = nil # DEV Where the player is heading.

      reset!
    end

    # @param cell [Cell] A cell to be added to the grid
    # @param overwrite [Boolean] Should the new cell replace a cell at the same position.
    # @return [Cell] The newly added cell.
    def add_cell(cell, overwrite = false)
      if overwrite
        other_cell = lookup cell.y, cell.x
        all_cells.delete(other_cell)
      else
        raise CellNotAvailableError unless cell_available?(cell.x, cell.y)
      end
      @cells[cell.y] ||= []
      @cells[cell.y][cell.x] = cell
      @all_cells << cell
      cell
    end

    # @param x [Fixnum] X position of the cell
    # @param y [Fixnum] Y position of the cell
    # @return [Boolean] Is the position on the grid free from any cell or not.
    def cell_available?(x, y)
      lookup(y, x).nil?
    end

    # TODO move to a specific builder
    def self.new_from_map(map)
      grid = new
      grid.generate_cells map
      grid
    end

    def tick(command)
      case command
      when 'player.wait'
      else
        return
      end

      start = lookup(@player[:y], @player[:x])

      if start != @destination
        @path = astar.find_path(start, @destination)
        if @path
          @player = { x: @path[1].x, y: @path[1].y }
          @path.shift
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
    # @return [Cell, nil] The cell at desired position or nil if there is no cell.
    def lookup(y,x)
      return nil if @cells[y].nil?
      @cells[y][x]
    end

    # Remove all cells from the grid
    def reset!
      @cells = []
      @all_cells = []
    end

    def prepare!
      assign_neighbours
    end

    # TODO Move this code to a specific builder
    # Creates all cells and creatures by reading the map.
    #
    # Currently, the available symbols are:
    #   - Walls: #
    #   - Destination: >
    #   - Stalkers: !
    #   - Player: @
    #   - Open floor: .
    def generate_cells(map)
      reset!

      (0...map.size).each do |y|
        @cells[y] = []
        next unless map[y]
        (0...map[y].size).each do |x|
          symbol = map[y] && map[y][x] || ' '
          case symbol
          when '!'
            cell = Cell.new x, y, wall: false
            add_cell cell
            @stalkers << { x: x, y: y }
          when '#'
            add_cell Cell.new x, y, wall: true
          when '.'
            add_cell Cell.new x, y, wall: false
          when '@'
            cell = Cell.new x, y, wall: false
            add_cell cell
            @player = { x: x, y: y }
          when '>'
            cell = Cell.new x, y, wall: false
            add_cell cell
            @destination = cell
          when ' '
            # do nothing
          end
        end
      end

      prepare!
    end

    private

    # Sets the neighbours of each cell of the grid.
    # This will be used by the A star pathfinding algorithm.
    def assign_neighbours
      @all_cells.each do |cell|

        x = cell.x
        y = cell.y

        [
          [x+1, y+1], [x, y+1], [x-1, y+1],
          [x+1, y], [x-1, y],
          [x+1, y-1], [x, y-1], [x-1, y-1]
        ].each do |x, y|
          cell.neighbours.push lookup(y, x)
        end

        cell.neighbours.compact!
      end
    end

    def astar
      @_astar = AStar.new
    end
  end
end
