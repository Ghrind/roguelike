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
# State:      obs.   Action:         input-wE       input-sE       input-I            input-D               NULL
#                                                           
# WANDERING    A     explore         ATTACKING:1    RETREATING:1   PICKING UP:1      ATTACKING:1
# ATTACKING    C     attack-ennemy                  RETREATING:1                     RETREATING:dt/maxhp   WANDERING:1
# PICKING UP   A     pickup-item     ATTACKING:ni   RETREATING:1   PICKING UP:1      ATTACKING:1           WANDERING:1
# RETREATING   C     flee                                          PICKING UP:nt                           WANDERING:1
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
# ni: no more items
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
      wandering: :all,
      attacking: :ennemies,
      picking_up: :all,
      retreating: :ennemies
    }

    STATES = {
      wandering: {
        weak_ennemies: [:attacking, 1],
        strong_ennemies: [:retreating, 1],
        valuable_item: [:picking_up, 1],
        damage_taken: [:attacking, 1]
      },

      attacking: {
        strong_ennemies: [:retreating, 1],
        damage_taken: [:retreating, :health_ratio],
        null: [:wandering, 1]
      },

      retreating: {
        valuable_item: [:picking_up, :no_more_threat],
        null: [:wandering, 1]
      },

      picking_up: {
        weak_ennemies: [:attacking, :no_more_items],
        strong_ennemies: [:retreating, 1],
        damage_taken: [:attacking, 1],
        null: [:wandering, 1]
      }
    }

    attr_reader :ennemies_threat, :item_worth

    def initialize(creature)
      @self = creature
      @ennemies = {}
      @items = []

      @current_state = :wandering
    end

    def on_damage_taken(amount)
      receive_input :damage_taken
    end

    def no_more_threat
      current_ennemy_threat < assess_self_threat ? 1 : 0
    end

    def no_more_items
      @items.empty? ? 1 : 0
    end

    def on_see_cell(cell)
      if cell.creature
        on_see_creature cell.creature
      end
      if cell.item
        on_see_item cell.item
      end
    end

    def on_see_item(item)
      worth = assess_item_worth(item)
      # FIXME Don't use hard coded value
      if worth > 4
        @items << item.clone unless @items.include?(item)
        receive_input :valuable_item
      end
    end

    def on_item_picked_up(item)
      @items.delete_if { |i| i.id == item.id }
    end

    def on_see_creature(creature)
      return if creature == @self || creature.faction == @self.faction # FIXME Move in another method
      @ennemies[creature] = assess_ennemy_threat(creature)
      current_threat = current_ennemy_threat - assess_self_threat

      if current_threat >= 0
        receive_input :strong_ennemies
      else
        receive_input :weak_ennemies
      end
    end

    def health_ratio
      (@self.max_hit_points - @self.hit_points).to_f / @self.max_hit_points
    end

    def receive_input(input)
      new_state, chance = STATES[@current_state][input]
      return if chance.nil?
      # TODO Check chance
      if chance.is_a?(Symbol)
        chance = self.send chance
      end
      if rand <= chance
        LOGGER.debug "Received #{input} while in #{@current_state}, changing state to #{new_state} (chance: #{chance})"
        @current_state = new_state
      else
        LOGGER.debug "Received #{input} while in #{@current_state}, but ignored (#{new_state} chance: #{chance})"
      end
    end

    def update_state(level)
      decrease_ennemy_threat

      case OBSERVATIONS[@current_state]
      when :ennemies
        if current_ennemy_threat == 0
          receive_input :null
        end
      when :all
        @items.delete_if do |item|
          cell = level.lookup(item.cell.x, item.cell.y)
          @self.fov.include?(cell) && cell.item.nil?
        end
        if current_ennemy_threat == 0 && @items.empty?
          receive_input :null
        end
      end
    end

    def on_creature_dies(cell)
      @ennemies.delete cell.creature
    end

    def act(level)
      update_state level

      LOGGER.debug @current_state
      case @current_state
      when :wandering
        # Try to explore an unknow cell
        start = @self.cell
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
            next if cell.wall
            @destination = cell.neighbours.find { |n| !@self.visited_cells.include?(n) }
            break if @destination
          end
          if @destination
            path = level.get_path(start, @destination, true)
          else
            move_at_random level
          end
          #LOGGER.debug "New random destination is #{@destination.inspect}"
        end

        if path
          LOGGER.debug "Found a path in #{path.length} steps"
        end

        # FIXME I crash when I have nothing more to explore
        if path && path[1].walkable?
          level.move_creature @self, path[1]
        else
          return move_at_random level
        end
        true
      when :picking_up
        start = @self.cell
        item = @items.first # TODO Pick the closest item / item in sight, otherwise creature may ignore close items in order to pick the first it ever saw
        destination = level.lookup(item.cell.x, item.cell.y) # Don't go to cell because it has been cloned
        if start == destination
          @self.pickup_from destination
        else
          path = level.get_path(start, destination, true)

          if path
            LOGGER.debug "Found a path in #{path.length} steps"
          end

          if path && path[1].walkable?
            level.move_creature @self, path[1]
          else
            return move_at_random level
          end
        end
        true
      when :retreating
        #LOGGER.debug @ennemies.inspect
        x = @ennemies.map { |e, _| e.cell.x }.avg
        y = @ennemies.map { |e, _| e.cell.y }.avg
        #LOGGER.debug "Dead center is #{x}.#{y}"

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
          start = @self.cell
          #LOGGER.debug "Fleeing to #{destination.inspect}"
          path = level.get_path(start, destination)

          if path
            LOGGER.debug "Found a path in #{path.length} steps"
          end

          if path && path[1].walkable?
            level.move_creature @self, path[1]
            return true
          else
            return move_at_random level
          end
        else
          return move_at_random level
        end

        true
      when :attacking
        start = @self.cell
        # FIXME I must chase the creature better
        # FIXME Choose a better target
        target = @self.fov.map { |c| c.creature }.find { |c| c && c != @self && c.alive && c.faction != @self.faction }
        unless target
          return false # Wait
        end
        #LOGGER.debug "New target: #{target.id} #{target.x} #{target.y}"
        destination = target.cell
        if start.neighbours.include?(destination)
          #LOGGER.debug "Hit #{target}"
          @self.attack(target)
        else
          #LOGGER.debug "Move closer to #{target}"
          path = level.get_path(start, destination, true)

          if path
            LOGGER.debug "Found a path in #{path.length} steps"
          end

          if path && path[1].walkable?
            level.move_creature @self, path[1]
          else
            return move_at_random level
          end
        end
        true
      end
    end

    def assess_item_worth(item)
      item.worth
    end

    def assess_self_threat
      @self.threat_level
    end

    def decrease_ennemy_threat
      @ennemies.keys.each do |ennemy|
        @ennemies[ennemy] = @ennemies[ennemy] - 1
        @ennemies.delete(ennemy) if @ennemies[ennemy] == 0
      end
    end

    def current_ennemy_threat
      @ennemies.values.sum
    end

    def move_at_random(level)
      target = @self.cell.neighbours.find_all { |c| c.walkable? }.sample
      return false unless target
      level.move_creature @self, target
      true
    end

    def assess_ennemy_threat(creature)
      creature.threat_level
    end
  end
end
