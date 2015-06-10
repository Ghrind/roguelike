require_relative 'level'
require_relative 'creature'

module Roguelike
  class Game
    attr_reader :player, :level, :creatures

    def initialize
      @creatures = []
      @player = Roguelike::Creature.new symbol: '@', light_radius: 5
      @creatures << @player
      @level = LevelBuilder.new.generate
      start = @level.cells.find_all { |c| c.start }.sample
      @level.enter @player, start
      10.times do
        creature = Roguelike::Creature.new symbol: 'S', light_radius: 5
        start = @level.cells.find_all { |c| c.walkable? }.sample
        @level.enter creature, start
        @creatures << creature
      end
    end

    # Translates the player input into an actual action
    # @return [true, false] Has the player input triggered an actual action
    def player_action(command)
      case command
      when 'player.wait'
        return true
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
      when /^player.open_close/
        direction = get_direction('player.open_close', command)
        target = @level.creature_destination(@player, direction)
        # TODO Ensure that target is reachable
        @level.creature_open_close(@player, target)
      else
        return false
      end
    end

    # Plays player action then all others events
    # Stops when player input is needed
    def tick(command)
      return unless player_action(command)

      @creatures.each do |c|
        # TODO Calculate FOV if player is in range
        @level.do_fov(c)
        dest = @level.lookup(@player.x, @player.y)
        # TODO Use scent + decay to help creature chase the player.
        if c.fov.include?(dest)
          c.last_destination = dest
          start = @level.lookup(c.x, c.y)
          next if start == dest
          path = level.get_path(start, dest, true)
          if path
            dest = level.lookup(path[1].x, path[1].y)
            if level.creature_can_move?(c, dest)
              level.move_creature c, dest
            end
          end
        end
      end

      true
    end

    private

    def get_direction(command_type, command)
      command.sub(command_type + '_', '').to_sym
    end
  end
end
