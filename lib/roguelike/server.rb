require 'faye/websocket'
require_relative 'game'
require_relative 'roguelike.pb.rb'

module Roguelike
  class Server
    attr_reader :game, :root

    def initialize(root)
      @root = Pathname.new(File.expand_path(root))
    end

    def application
      lambda do |env|
        if Faye::WebSocket.websocket?(env)
          ws = Faye::WebSocket.new(env)

          ws.on :message do |event|
            time = Time.now
            data = apply_command event.data
            message = game_message event.data, data
            ws.send(message.bytes)
            elapsed_time = (Time.now - time) * 1000.0
            puts "Responded to '#{event.data}' in #{elapsed_time.ceil} milliseconds"
          end

          ws.on :close do |event|
            # p [:close, event.code, event.reason]
            ws = nil
          end

          # Return async Rack response
          ws.rack_response
        else
          respond_http env
        end
      end
    end

    private

    def start_new_game
      @game = Roguelike::Game.new
    end

    def send(filename, content_type)
      [200, { 'Content-Type' => content_type }, File.read(@root.join(filename))]
    end

    def render_404(request_path)
      [404, { 'Content-Type' => 'text/plain' }, "Not found '#{request_path}'"]
    end

    def respond_http(env)
      request_path = trim_path(env['PATH_INFO'])
      case request_path
      when ''
        send 'index.html', 'text/html'
      when 'roguelike.proto'
        send request_path, 'application/x-protobuf'
      when 'ByteBufferAB.min.js', 'ProtoBuf.min.js'
        send request_path, 'application/javascript'
      else
        #puts "404 - Not found - '#{env['PATH_INFO']}'"
        render_404 env['PATH_INFO']
      end
    end

    def trim_path(path)
      path.to_s.sub(/^\//, '')
    end

    def game_command(command)
      game.tick(command)

      # TODO Try to avoid calculating FOV if possible
      game.level.do_fov(game.player)
      game.player.changed!

      cells = game.player.visited_cells.find_all { |c| c.changed }
      creatures = game.creatures.find_all { |c| c.changed }
      {
        cells: cells,
        player: game.player, # TODO Don't send player it he didn't change
        creatures: creatures
      }
    end

    # FIXME Refactor
    def game_message(command, data)
      message = Roguelike::GameMessage.new
      message.command = command
      if data[:cells]
        data[:cells].map do |cell|
          msg = Roguelike::CellMessage.new
          msg.id = cell.id
          msg.x = cell.x
          msg.y = cell.y
          msg.symbol = cell.current_symbol
          msg.item_worth = cell.item.worth if cell.item
          msg.creature_id = cell.creature.id if cell.creature
          message.cells << msg
          cell.changed = false
        end
      end
      if data[:creatures]
        data[:creatures].map do |creature|
          msg = Roguelike::CreatureMessage.new
          msg.id = creature.id
          msg.x = creature.x
          msg.y = creature.y
          msg.symbol = creature.symbol
          message.creatures << msg
          creature.changed = false
        end
      end
      player = data[:player]
      if player
        message.player_id = player.id
        message.fov = player.fov.map { |c| c.id }
      end

      message.serialize_to_string
    end

    def current_state
      game.level.do_fov(game.player)
      cells = game.player.visited_cells
      creatures = [game.player]
      {
        cells: cells,
        player: game.player,
        creatures: game.creatures # TODO Show less creatures
      }
    end

    def apply_command(command)
      case command
      when 'game.new'
        start_new_game
        {}
      when 'game.current_state'
        current_state
      else
        game_command command
      end
    end
  end
end
