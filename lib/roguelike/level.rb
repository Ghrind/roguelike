require_relative 'cell'
require_relative 'astar'
require_relative 'level_builder'
require_relative 'field_of_view'

module Roguelike
  # The grid knows everything that is contained in a level and knows how to find path between them.
  #
  # The x position of a cell is it which column it belongs.
  # The y position of a cell is it which row it belongs.
  class Level
    include ShadowcastingFieldOfView

    # Contains the cells organized by rows and columns
    attr_accessor :grid

    # Contains the cells in an array
    attr_accessor :cells

    def initialize
      reset!
    end

    def enter(creature, start_cell)
      creature.step_in(start_cell)
      do_fov creature
    end

    def blocked?(x, y)
      !lookup(x, y).see_through?
    end

    def light(creature, x, y)
      cell = lookup(x, y)
      creature.see cell
    end

    def set_cells(feature)
      reset!
      @cells = feature.cells
      @grid = feature.grid
      assign_neighbours
    end

    def move_creature(creature, destination)
      creature.step_out(creature.cell)
      creature.step_in(destination)
      true
    end

    def creature_open_close(creature, target)
      if target.closed?
        target.open!
      elsif target.open?
        target.close!
      else
        false
      end
    end

    def creature_can_move?(creature, destination)
      destination_reachable? destination
    end

    def creature_destination(creature, direction)
      start = creature.cell
      lookup(*start.coordinates.at(direction).to_a)
    end

    def destination_reachable?(destination)
      !destination.nil? && destination.walkable?
    end

    # @param y [Fixnum] The index of the row.
    # @param x [Fixnum] The index of the column.
    # @return [Cell, nil] The cell at desired position or nil if there is no cell.
    def lookup(x,y)
      return nil if @grid[y].nil?
      @grid[y][x]
    end

    # Remove all cells from the grid
    def reset!
      @cells = nil
      @grid = nil
    end

    def get_path(start, destination, assume_goal_is_free = false)
      astar.find_path start, destination, assume_goal_is_free
    end

    private

    # Sets the neighbours of each cell of the grid.
    # This will be used by the A star pathfinding algorithm.
    def assign_neighbours
      @cells.each do |cell|

        x = cell.x
        y = cell.y

        # FIXME Use Coordinates instead
        [
          [x+1, y+1], [x, y+1], [x-1, y+1],
          [x+1, y], [x-1, y],
          [x+1, y-1], [x, y-1], [x-1, y-1]
        ].each do |x, y|
          cell.neighbours.push lookup(x, y)
        end

        cell.neighbours.compact!
      end
    end

    def astar
      @_astar = AStar.new
    end
  end
end
