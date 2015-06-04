require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
  add_filter '/vendor/'
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'roguelike'

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
