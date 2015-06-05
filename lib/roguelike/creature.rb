module Roguelike
  class Creature
    ATTRIBUTES = {
      x: 0,
      y: 0,
      symbol: '?',
      light_radius: 2
    }

    attr_accessor *ATTRIBUTES.keys
    attr_accessor :fov
    attr_reader :id
    attr_accessor :changed
    attr_reader :visited_cells

    def self.generate_id
      @_id = (@_id || -1).next
    end

    def initialize(attributes = {})
      ATTRIBUTES.merge(attributes).each_pair do |k, v|
        send "#{k}=", v
      end

      @fov = []
      @visited_cells = []
      @id = self.class.generate_id
      @changed = true
    end

    def step_in(cell)
      self.x = cell.x
      self.y = cell.y
      visit cell
      cell.on_step_in(self)
      changed!
    end

    def step_out(cell)
      cell.on_step_out(self)
      self.x = nil
      self.y = nil
      changed!
    end

    def in_sight?(cell)
      @fov.include?(cell)
    end

    def visited?(cell)
      @visited_cells.include?(cell)
    end

    def visit(cell)
      unless visited?(cell)
        @visited_cells << cell
        cell.changed!
        changed!
      end
    end

    def changed!
      @changed = true
    end
  end
end
