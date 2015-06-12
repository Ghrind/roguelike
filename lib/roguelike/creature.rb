require_relative 'ai'

module Roguelike
  class Creature
    ATTRIBUTES = {
      x: 0,
      y: 0,
      symbol: '?',
      light_radius: 2,
      hit_points: 1,
      max_hit_points: 1,
      threat_level: 1,
      alive: true
    }

    attr_accessor *ATTRIBUTES.keys
    attr_accessor :fov
    attr_reader :id
    attr_accessor :changed
    attr_reader :visited_cells
    attr_reader :ai

    def self.generate_id
      @_id = (@_id || -1).next
    end

    def initialize(attributes = {})
      ai_class = attributes.delete(:ai)

      ATTRIBUTES.merge(attributes).each_pair do |k, v|
        send "#{k}=", v
      end

      @fov = []
      @visited_cells = []
      @id = self.class.generate_id
      @changed = true

      if ai_class
        @ai = ai_class.new(self)
      end
    end

    def pickup_from(cell)
      cell.remove_item(cell.item)
      # TODO Add to creature's items
    end

    def attack(other_creature)
      other_creature.take_damage(1)
    end

    def take_damage(amount)
      @hit_points -= amount
      if @hit_points <= 0
        @alive = false
      end
      LOGGER.debug "took #{amount} damage, now at #{@hit_points} (alive? #{alive})"
      changed!
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
