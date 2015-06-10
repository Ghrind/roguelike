require_relative 'level'
require_relative 'creature'

module Roguelike
  class Game
    attr_reader :player, :level

    def initialize
      @player = Roguelike::Creature.new symbol: '@', light_radius: 5
      @level = LevelBuilder.new.generate
      start = @level.cells.find_all { |c| c.start }.sample
      @level.enter @player, start
    end

    def tick(command)
      case command
      when 'player.wait'
      when /^player\.move_/
        direction = get_direction('player.move', command)
        if @level.creature_can_move?(@player, direction)
          @level.move_creature(@player, direction)
        else
          # TODO Try another action on the cell
        end
      when /^player.open_close/
        @level.creature_open_close(@player, get_direction('player.open_close', command))
      else
        return
      end

      #@stalkers.each do |s|
      #  start = lookup(s[:x], s[:y])
      #  dest = lookup(@player.x, @player.y)
      #  next if start == dest
      #  path = astar.find_path(start, dest)
      #  if path
      #    s[:x] = path[1].x
      #    s[:y] = path[1].y
      #  end
      #end

      true
    end

    private

    def get_direction(command_type, command)
      command.sub(command_type + '_', '').to_sym
    end
  end
end
