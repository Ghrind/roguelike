module Roguelike
  # Contains all the informations about a square from the game.
  #
  # Every cell has pointer to its neighbours in order to ease the path finding.
  class Cell
    attr_reader :wall, :x, :y
    attr_accessor :neighbours
    attr_accessor :direction # An indication of where is the outside of the room from this cell

    # @param x [Fixnum] The x position of the cell on the grid
    # @param y [Fixnum] The y position of the cell on the grid
    # @param wall [Boolean] Is the cell a wall?
    def initialize(x, y, attributes = {})
      @x = x
      @y = y

      @wall = attributes[:wall]
      @direction = attributes[:direction]

      @neighbours = []
    end

    # @return [Array<Cell>] All adjacent cells that a creature can walk onto.
    def walkable_neighbours
      @neighbours.select { |n| n.walkable? }
    end

    # @return [Boolean] Can a creature walk onto the cell?
    def walkable?
      !wall
    end

    # @return [String] A string with the attributes of the cell
    def inspect
      "#<Cell:#{object_id} @x=#{x}, @y=#{y}, @wall=#{wall}, @direction=#{direction.inspect}>"
    end
  end
end
