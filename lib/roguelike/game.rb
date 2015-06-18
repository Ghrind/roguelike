require_relative 'level'
require_relative 'creature'
require_relative 'item'

require 'logger'
LOGGER = Logger.new('log/ai.log')

module Roguelike
  class Game
    attr_reader :player, :level, :creatures

    def initialize
      @creatures = []
      @player = Roguelike::Creature.new symbol: '@', light_radius: 6, ai: Roguelike::WandererAI, threat_level: 5, max_hit_points: 999, hit_points: 999, faction: 1
      @creatures << @player
      @level = LevelBuilder.new.generate
      start = @level.cells.find_all { |c| c.start }.sample
      @level.enter @player, start
      10.times do
        if rand(10).next > 5
          creature = Roguelike::Creature.new symbol: 'M', light_radius: 5, threat_level: 10, hit_points: 3, ai: Roguelike::WandererAI, faction: 2
        else
          creature = Roguelike::Creature.new symbol: 'm', light_radius: 5, threat_level: 2, hit_points: 3, ai: Roguelike::WandererAI, faction: 2
        end
        start = @level.cells.find_all { |c| c.walkable? }.sample
        @level.enter creature, start
        @creatures << creature
      end
      10.times do
        item = Roguelike::Item.new worth: rand(10).next
        cell = @level.cells.find_all { |c| c.walkable? }.sample
        item.cell = cell
        cell.item = item
      end
    end

    # Translates the player input into an actual action
    # @return [true, false] Has the player input triggered an actual action
    def player_action(command)
      case command
      when 'player.wait'
        return player.ai.act(level)
        #return true
      when /^player\.move_/
        direction = get_direction('player.move', command)
        destination = @level.creature_destination(@player, direction)
        if @level.creature_can_move?(@player, destination)
          @level.move_creature(@player, destination)
          return true
        else
          if destination.creature
            player.attack destination.creature
            return true
          end
          return false
        end
      when /^player.open_close_/
        direction = get_direction('player.open_close', command)
        target = @level.creature_destination(@player, direction)
        # TODO Ensure that target is reachable
        @level.creature_open_close(@player, target)
      when 'player.pickup'
        start = @player.cell
        if start.item
          return @player.pickup_from(start)
        else
          return false
        end
      else
        return false
      end
    end

    # Plays player action then all others events
    # Stops when player input is needed
    def tick(command)
      return unless player_action(command)

      @creatures.each do |creature|
        if creature.alive && creature != player
          LOGGER.debug "Creature##{creature.id} acts"
          creature.ai.act(level)
          level.do_fov(creature)
        end
      end

      level.do_fov(player)

      true
    end

    def ended?
      return :dead unless player.alive
      false
    end

    private

    def get_direction(command_type, command)
      command.sub(command_type + '_', '').to_sym
    end
  end
end
