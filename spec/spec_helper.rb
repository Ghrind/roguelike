$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'roguelike'

def grid_from_map(map)
  Roguelike::Grid.new_from_map map
end
