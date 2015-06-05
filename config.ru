require 'rubygems'
require "bundler/setup"

require 'faye/websocket'
require 'roguelike'
require_relative 'roguelike.pb.rb'

game = Roguelike::Game.new
#game.play

App = lambda do |env|
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env)

    ws.on :message do |event|
      case event.data
      when 'showme'
        ws.send(game.to_message.bytes)
      when 'hello'
        p 'Somebody is listening'
      else
        game.tick(event.data)
        ws.send(game.to_message.bytes)
      end
    end

    ws.on :close do |event|
      p [:close, event.code, event.reason]
      ws = nil
    end

    # Return async Rack response
    ws.rack_response

  else
    local_file = env['REQUEST_PATH'] == '/' ? 'index.html' :  File.join('.', env['REQUEST_PATH'])
    # Normal HTTP request
    [200, {'Content-Type' => 'text/html'}, File.read(local_file)]
  end
end

Faye::WebSocket.load_adapter('thin')

run App
