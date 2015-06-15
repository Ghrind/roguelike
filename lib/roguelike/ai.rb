# What does the creature may want to do in the dungeon
#
# - Explore
# - Hunt
# - Eat
# - Guard
# - Work
# - Live

# commoner: [:survive, :feed, :idle]
# berserker: [:kill_most_hated, :survive, :feed]
# fighter: [:survive, :feed, :kill_most_hated]
# assassin: [:survive, :feed, :kill_target]
# defender: [:survive, :feed, :defend_most_loved]
# holy_defender: [:defend_most_loved, :survive, :feed]
# beast: [:survive, :feed, :idle]

# WANDERER
#
# The wanderer walks through the dungeon to pick up valuable items.
# They are careful and will not fight to death or if the ennemy is too powerful.
#
# State:      obs.   Action:         input-wE          input-sE       input-I            input-D               NULL
#                                                              
# WANDERING    A     explore         ATTACKING:et      RETREATING:1   PICKING UP:iw      ATTACKING:2
# ATTACKING    C     attack-ennemy                     RETREATING:1                      RETREATING:dt/maxhp   WANDERING:1
# PICKING UP   A     pickup-item     ATTACKING:iw/et   RETREATING:1   PICKING UP:iw      ATTACKING:1           WANDERING:1
# RETREATING   C     flee                                             PICKING UP:et/iw                         WANDERING:1
#
# input-wE: Weaker ennemies detected
# input-sE: Stronger ennemies detected
# input-I: Valuable item detected
# input-D: Damage taken
# di: distance item
# de: distance ennemy
# dt: damage taken
# hp: max hit points
# iw: Item worth
# et: Ennemies threat
class Array
  def sum
    inject(0) { |sum, value| sum += value }
  end

  def avg
    return 0 if empty?
    ( sum.to_f / size ).round
  end
end

module Roguelike
  class WandererAI

    OBSERVATIONS = {
      wandering: [:weak_ennemies, :strong_ennemies, :valuable_item, :damage_taken],
      attacking: [:strong_ennemies, :damage_taken],
      picking_up: [:weak_ennemies, :strong_ennemies, :valuable_item, :damage_taken],
      retreating: [:strong_ennemies, :weak_ennemies]
    }

    STATES = {
      wandering: {
        weak_ennemies: [:attacking, :ennemies_threat],
        strong_ennemies: [:retreating, 999],
        valuable_item: [:picking_up, :item_worth],
        damage_taken: [:attacking, 998]
      },

      attacking: {
        strong_ennemies: [:retreating, 999],
        damage_taken: [:retreating, :health_ratio], # TODO health ratio
        null: [:wandering, 1]
      },

      retreating: {
        #valuable_item: [:picking_up, 1], # TODO Make the wanderer choose if item is worth picking up (versus continue retreat)
        null: [:wandering, 1]
      },

      picking_up: {
        weak_ennemies: [:attacking, :ennemies_threat],
        strong_ennemies: [:retreating, 999],
        valuable_item: [:picking_up, :item_worth],
        damage_taken: [:attacking, 998],
        null: [:wandering, 1]
      }
    }

    attr_reader :ennemies_threat, :item_worth

    def initialize(creature)
      @self = creature
      @ennemies = {}
      @last_hit_points = @self.hit_points

      @current_state = :wandering

      @ennemies_threat = 0
      @item_worth = 0
    end

    def observe
      inputs_to_check = OBSERVATIONS[@current_state]
      inputs = []
      if inputs_to_check.include?(:strong_ennemies) || inputs_to_check.include?(:weak_ennemies)
        @ennemies_threat = assess_ennemies_threat
        LOGGER.debug "Ennemy threats: #{@ennemies.values.inspect}"
        if @ennemies_threat >= assess_self_threat
          inputs << :strong_ennemies
        elsif @ennemies_threat > 0
          inputs << :weak_ennemies
        end
        # TODO When to decrement ennemies threat?
      end

      if inputs_to_check.include?(:damage_taken)
        if @last_hit_points > @self.hit_points
          inputs << :damage_taken# = @self.hit_points.to_f / @self.max_hit_points
        end
      end

      if inputs_to_check.include?(:valuable_item)
        @item_location, @item_worth = assess_most_valuable_item
        if @item_worth > 0
          inputs << :valuable_item
        end
      end

      inputs << :null if inputs.empty?

      inputs
    end

    def update_state
      inputs = observe
      LOGGER.debug "Current inputs: #{inputs}"
      state_priority = 0
      new_state = nil
      inputs.each do |input|
        state, priority = STATES[@current_state][input]
        next unless state
        priority = send(priority) if priority.is_a? Symbol
        LOGGER.debug "  #{state}: #{priority}"
        if priority > state_priority
          state_priority = priority
          new_state = state
        end
      end
      LOGGER.debug "New state: #{new_state} (#{state_priority})"
      @current_state = new_state if new_state
      LOGGER.debug @current_state
    end

    def act(level)
      update_state
      case @current_state
      when :wandering
        # Try to explore an unknow cell
        start = level.lookup(@self.x, @self.y)
        path = nil
        if @self.visited_cells.include?(@destination)
          @destination = nil
        end
        if @destination
          path = level.get_path(start, @destination, true)
        end

        if @destination.nil? || path.nil?
          (@self.visited_cells.length - 1).downto(0) do |i|
            cell = @self.visited_cells[i]
            @destination = cell.neighbours.find { |n| !@self.visited_cells.include?(n) }
            break if @destination
          end
          path = level.get_path(start, @destination, true)
          LOGGER.debug "New random destination is #{@destination.inspect}"
        end

        # FIXME I crash when I have nothing more to explore
        if path
          level.move_creature @self, path[1]
        else
          LOGGER.debug "Can't find a way to #{@destination.inspect}"
          return false
        end
        true
      when :picking_up
        start = level.lookup(@self.x, @self.y)
        if start == @item_location
          @self.pickup_from(@item_location)
        else
          path = level.get_path(start, @item_location, true)
          level.move_creature @self, path[1]
        end
        true
      when :retreating
        #LOGGER.debug @ennemies.inspect
        x = @ennemies.map { |e, _| e.x }.avg
        y = @ennemies.map { |e, _| e.y }.avg
        LOGGER.debug "Dead center is #{x}.#{y}"

        destination = nil
        distance = 0
        @self.fov.each do |cell|
          next unless cell.walkable?
          new_distance = (cell.x - x)**2 + (cell.y - y)**2
          if new_distance > distance
            destination = cell
            distance = new_distance
          end
        end

        if destination
          start = level.lookup(@self.x, @self.y)
          LOGGER.debug "Fleeing to #{destination.inspect}"
          path = level.get_path(start, destination)
          if path
            level.move_creature @self, path[1]
            return true
          else
            return false # Can't do anything
          end
        else
          return false # Can't do anything
        end

        true
      when :attacking
        start = level.lookup(@self.x, @self.y)
        # FIXME I must chase the creature better
        target = @self.fov.map { |c| c.creature }.find { |c| c && c != @self && c.alive }
        unless target
          return false # Wait
        end
        LOGGER.debug "New target: #{target.id} #{target.x} #{target.y}"
        destination = level.lookup(target.x, target.y)
        if start.neighbours.include?(destination)
          LOGGER.debug "Hit #{target}"
          @self.attack(target)
        else
          LOGGER.debug "Move closer to #{target}"
          path = level.get_path(start, destination, true)
          level.move_creature @self, path[1]
        end
        true
      end
    end

    def assess_most_valuable_item
      item_location = nil
      worth = 0
      @self.fov.each do |cell|
        next unless cell.item
        item_worth = assess_item_worth(cell.item)
        if item_worth > worth
          item_location = cell
          worth = item_worth
        end
      end
      [item_location, worth]
    end

    def assess_item_worth(item)
      item.worth
    end

    def assess_self_threat
      @self.threat_level
    end

    def assess_ennemies_threat
      @ennemies.keys.each do |ennemy|
        @ennemies[ennemy] = @ennemies[ennemy] - 1
        @ennemies.delete(ennemy) if @ennemies[ennemy] == 0
      end
      @self.fov.each do |cell|
        next if cell.creature.nil? || cell.creature == @self
        @ennemies[cell.creature] = assess_ennemy_threat(cell.creature)
      end
      @ennemies.values.sum
    end

    def assess_ennemy_threat(creature)
      creature.threat_level
    end
  end
end
