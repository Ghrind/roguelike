module Roguelike
  class Coordinates
    attr_accessor :x, :y

    def initialize x, y
      @x = x
      @y = y
    end

    def at(direction)
      case direction
      when :up
        new_x = x
        new_y = y - 1
      when :down
        new_x = x
        new_y = y + 1
      when :left
        new_x = x - 1
        new_y = y
      when :right
        new_x = x + 1
        new_y = y
      when :up_left
        new_y = y - 1
        new_x = x - 1
      when :down_left
        new_y = y + 1
        new_x = x - 1
      when :up_right
        new_y = y - 1
        new_x = x + 1
      when :down_right
        new_y = y + 1
        new_x = x + 1
      else
        raise ArgumentError, "Unknown direction #{direction.inspect}"
      end

      self.class.new new_x, new_y
    end

    def to_a
      [x, y]
    end
  end
end
