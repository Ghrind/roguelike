require_relative 'game'
require_relative 'roguelike.pb.rb'

module Roguelike
  class Application
    attr_reader :game, :root

    def initialize(root)
      @game = Roguelike::Game.new
      @game.level.do_fov(game.player)
      @root = Pathname.new(File.expand_path(root))
    end

    def send(filename, content_type)
      [200, { 'Content-Type' => content_type }, File.read(@root.join(filename))]
    end

    def render_404(request_path)
      [404, { 'Content-Type' => 'text/plain' }, "Not found '#{request_path}'"]
    end

    def respond_http(env)
      request_path = trim_path(env['REQUEST_PATH'])
      case request_path
      when ''
        send 'index.html', 'text/html'
      when 'roguelike.proto'
        send request_path, 'application/x-protobuf'
      when 'ByteBufferAB.min.js', 'ProtoBuf.min.js'
        send request_path, 'application/javascript'
      else
        puts "404 - Not found - '#{env['REQUEST_PATH']}'"
        render_404 env['REQUEST_PATH']
      end
    end

    def trim_path(path)
      path.to_s.sub(/^\//, '')
    end

    def apply_command(command)
      case command
      when 'system.init'
        current_state
      else
        game_command command
      end
    end

    def game_command(command)
      game.tick(command)
      game.level.do_fov(game.player)
      cells = game.player.visited_cells.find_all { |c| c.changed }
      creatures = [game.player].find_all { |c| c.changed }
      {
        cells: cells,
        player: creatures.first
      }
    end

    def game_message(command, data)
      message = Roguelike::GameMessage.new
      message.command = command
      data[:cells].map do |cell|
        msg = Roguelike::CellMessage.new
        msg.id = cell.id
        msg.x = cell.x
        msg.y = cell.y
        msg.symbol = cell.symbol
        message.cells << msg
        cell.changed = false
      end
      player = data[:player]
      if player
        player.changed = false
        player_message = Roguelike::CreatureMessage.new
        player_message.id = player.id
        player_message.x = player.x
        player_message.y = player.y
        player_message.symbol = player.symbol
        message.player = player_message

        message.fov = player.fov.map { |c| c.id }
      end

      message.serialize_to_string
    end

    def current_state
      cells = game.player.visited_cells
      creatures = [game.player]
      {
        cells: cells,
        player: creatures.first
      }
    end

    def server
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
            p [:close, event.code, event.reason]
            ws = nil
          end

          # Return async Rack response
          ws.rack_response
        else
          respond_http env
        end
      end
    end
  end
end
