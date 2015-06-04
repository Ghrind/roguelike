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

    def initialize(attributes = {})
      ATTRIBUTES.merge(attributes).each_pair do |k, v|
        send "#{k}=", v
      end

      @fov = []
      @visited_cells = []
    end

    def step_in(cell)
      self.x = cell.x
      self.y = cell.y
      visit cell
      cell.on_step_in(self)
    end

    def step_out(cell)
      cell.on_step_out(self)
      self.x = nil
      self.y = nil
    end

    def in_sight?(cell)
      @fov.include?(cell)
    end

    def visited?(cell)
      @visited_cells.include?(cell)
    end

    def visit(cell)
      @visited_cells << cell unless visited?(cell)
    end
  end
end
