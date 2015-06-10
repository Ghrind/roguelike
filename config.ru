require 'rubygems'
require "bundler/setup"

require 'roguelike'

Faye::WebSocket.load_adapter('thin')

server = Roguelike::Server.new 'public'

run server.application
