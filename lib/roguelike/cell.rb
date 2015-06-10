require_relative 'coordinates'

module Roguelike
  # Contains all the informations about a square from the game.
  #
  # Every cell has pointer to its neighbours in order to ease the path finding.
  class Cell
    attr_accessor :neighbours
    attr_reader :creature
    attr_reader :coordinates
    attr_reader :id
    attr_accessor :changed

    ATTRIBUTES = {
      wall: false,        # Is the cell a boudary of an open space?
      direction: :none,   # An indication of where is the outside of the room from this cell
      symbol: '?',        # How is the cell displayed on a map.
      start: false,       # DEV Is this cell the starting location of the level
      transparent: false, # Can creatures see through this cell
      door: false,        # Does this cell behahe like a door
      open: true,         # If this cell is a door, is it closed?
      open_symbol: 'd'
    }

    attr_accessor *ATTRIBUTES.keys

    def self.generate_id
      @_id = (@_id || -1).next
    end

    # @param x [Fixnum] The x position of the cell on the grid
    # @param y [Fixnum] The y position of the cell on the grid
    # @param wall [Boolean] Is the cell a wall?
    def initialize(x, y, attributes = {})
      @coordinates = Roguelike::Coordinates.new x, y

      ATTRIBUTES.merge(attributes).each_pair do |k, v|
        send "#{k}=", v
      end

      @neighbours = []
      @creature = nil
      @id = self.class.generate_id
      @changed = true
    end

    def current_symbol
      open? ? open_symbol : symbol
    end

    def clone
      attributes = Hash[ATTRIBUTES.keys.map { |k| [k, send(k)] }]
      self.class.new x, y, attributes
    end

    def x
      coordinates.x
    end

    def y
      coordinates.y
    end

    def x=(value)
      coordinates.x = value
    end

    def y=(value)
      coordinates.y = value
    end

    def neighbour(direction)
      new_x, new_y = *coordinates.at(direction).to_a
      @neighbours.find { |c| c.x == new_x && c.y == new_y }
    end

    def see_through?
      door ? open : transparent
    end

    def on_step_in(creature)
      @creature = creature
      open! if closed?
      changed!
    end

    def open?
      door && open
    end

    def closed?
      door && !open
    end

    def open!
      return false unless closed?
      self.open = true
      changed!
    end

    def close!
      return false unless open?
      return false if creature
      self.open = false
      changed!
    end

    def on_step_out(creature)
      changed! unless @creature.nil?
      @creature = nil
    end

    # @return [Boolean] Can a creature walk onto the cell?
    def walkable?
      !wall && creature.nil?
    end

    # @return [String] A string with the attributes of the cell
    def inspect
      "#<Cell:#{object_id} #{(instance_variables - [:@neighbours]).map { |v| "#{v}=#{instance_variable_get(v).inspect}" }.join ', '}>"
    end

    def changed!
      @changed = true
    end
  end
end
