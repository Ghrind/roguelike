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
      @player = Roguelike::Creature.new symbol: '@', light_radius: 8, ai: Roguelike::WandererAI, threat_level: 5, max_hit_points: 10, hit_points: 10
      @creatures << @player
      @level = LevelBuilder.new.generate
      start = @level.cells.find_all { |c| c.start }.sample
      @level.enter @player, start
      10.times do
        creature = Roguelike::Creature.new symbol: 'S', light_radius: 5, threat_level: rand(10).next, hit_points: 1, ai: Roguelike::WandererAI
        start = @level.cells.find_all { |c| c.walkable? }.sample
        @level.enter creature, start
        @creatures << creature
      end
      10.times do
        item = Roguelike::Item.new rand(10).next
        cell = @level.cells.find_all { |c| c.walkable? }.sample
        cell.item = item
      end
    end

    # Translates the player input into an actual action
    # @return [true, false] Has the player input triggered an actual action
    def player_action(command)
      case command
      when 'player.wait'
        player.ai.act(level)
        # return true FIXME This was supposed to be the correct wait behavior
      when /^player\.move_/
        direction = get_direction('player.move', command)
        destination = @level.creature_destination(@player, direction)
        if @level.creature_can_move?(@player, destination)
          @level.move_creature(@player, destination)
          return true
        else
          # TODO Try another action on the cell
          return false
        end
      when /^player.open_close_/
        direction = get_direction('player.open_close', command)
        target = @level.creature_destination(@player, direction)
        # TODO Ensure that target is reachable
        @level.creature_open_close(@player, target)
      when 'player.pickup'
        cell = @level.lookup(@player.x, @player.y)
        if cell.item
          return @player.pickup_from(cell)
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
        if creature.alive && creature.symbol != '@' # FIXME
          LOGGER.debug "Creature##{creature.id} acts"
          creature.ai.act(level)
        end
      end

      dead_creatures = creatures.find_all { |c| !c.alive }
      dead_creatures.each do |creature|
        creatures.delete creature
        cell = level.lookup creature.x, creature.y
        cell.creature = nil
        cell.changed!
      end

      true
    end

    private

    def get_direction(command_type, command)
      command.sub(command_type + '_', '').to_sym
    end
  end
end
