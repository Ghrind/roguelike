# Test coverage
require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
end

# Application
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'roguelike'

# Rack test
require 'rack/test'
include Rack::Test::Methods

# Websocket test
require_relative 'websocket_helper'
include WebsocketHelper

# Helpers
def coordinates(cell)
  [cell.x, cell.y]
end

def feature_from_map(map)
  feature = Roguelike::Feature.new
  feature.build map
end

def level_from_map(map)
  level = Roguelike::Level.new
  feature = feature_from_map map
  level.set_cells feature
  level
end

def parse_game_message(string)
  message = Roguelike::GameMessage.new
  message.parse_from_string string
end
