require_relative 'level'
require_relative 'creature'

module Roguelike
  class Game
    def initialize
      @player = Roguelike::Creature.new symbol: '@', light_radius: 5
      @level = LevelBuilder.new.generate
      start = @level.cells.find_all { |c| c.start }.sample
      @level.enter @player, start
    end

    def to_message
      message = Roguelike::GameMessage.new
      @level.cells.map do |cell|
        msg = Roguelike::CellMessage.new
        msg.x = cell.x
        msg.y = cell.y
        msg.symbol = cell.symbol
        message.cells << msg
      end
      player_message = Roguelike::CreatureMessage.new
      player_message.x = @player.x
      player_message.y = @player.y
      player_message.symbol = @player.symbol
      message.player = player_message

      message.serialize_to_string
    end

    def tick(command)
      case command
      when 'player.wait'
      when /^player\.move_/
        direction = command.sub('player.move_', '').to_sym
        if @level.creature_can_move?(@player, direction)
          @level.move_creature(@player, direction)
        else
          # TODO Try another action on the cell
        end
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
  end
end
