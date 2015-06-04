require_relative 'feature'

module Roguelike
  class LevelBuilder
    def initialize(options = {})
      @options = {
        #height: 20,
        #width: 20,
        iterations: 50,
        room_min_size: 6,
        room_max_size: 13
      }.merge(options)

      @level = Level.new
    end

    def random_room_size
      rand(1 + @options[:room_max_size] - @options[:room_min_size]) + @options[:room_min_size]
    end

    def generate
      # First we put a room at the center of the map
      main_feature = Feature.new.build([
        '   #####   ',
        '  ##...##  ',
        '###.....###',
        '#...#.#...#',
        '#....s....#',
        '#...#.#...#',
        '###.....###',
        '  ##...##  ',
        '   #####   '
      ])

      # Main loop
      @options[:iterations].times do
     
        # A new room
        width = random_room_size
        height = random_room_size
        new_room = SquareRoom.new.build width, height
        #new_room = Feature.new.build [
        #  '#######',
        #  '#.....#',
        #  '##...##',
        #  ' ##.## ',
        #  '  ###  '
        #]
     
        # A corridor
        new_room.rotate Feature::GRAVITIES.sample
        if rand(2) == 1
          corridor = Corridor.new.build 3, random_room_size
          j1 = new_room.available_junctions(:south).sample
          j2 = corridor.available_junctions(:south).sample
          j3 = corridor.available_junctions(:north).sample
          new_room.rotate j2.direction
          new_room.merge corridor, j1.x, j1.y, j2.x, j2.y, junction: :door
          new_room.rotate j3.direction
        else
          j3 = new_room.available_junctions(:south).sample
        end
     
        j1 = main_feature.available_junctions.sample
        new_room.rotate j1.direction
     
        if main_feature.mergeable?(new_room, j1.x, j1.y, j3.x, j3.y)
          main_feature.merge new_room, j1.x, j1.y, j3.x, j3.y, junction: :door
          last_room = new_room
        end
      end

      last_room = main_feature

      # Add exit in the last room
      end_cell = last_room.cells.find_all { |c| c.walkable? }.sample

      @level.set_cells main_feature

      File.open(File.join('log', 'level_dump.txt'), 'w') do |file|
        file.puts main_feature.to_map.join("\n")
      end

      @level
    end
  end
end
