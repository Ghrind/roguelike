require 'rubygems'
require "bundler/setup"

require 'faye/websocket'
require 'roguelike'

Faye::WebSocket.load_adapter('thin')

application = Roguelike::Application.new 'public'

run application.server
