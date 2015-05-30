require 'simplecov'
SimpleCov.start

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'roguelike'

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
