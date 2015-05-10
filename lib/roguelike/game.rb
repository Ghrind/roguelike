require 'curses'
require_relative 'grid'

module Roguelike
  # Inspired by https://github.com/aka-bo/ruby-curses-conway
  class Game
    def initialize
      Curses.init_screen
      Curses.crmode
      Curses.curs_set 0
      Curses.noecho
      Curses.start_color

      # Curses.stdscr.keypad(true) # enable arrow keys (required for pageup/down)

      Curses.init_pair(Curses::COLOR_BLACK, Curses::COLOR_BLACK, Curses::COLOR_BLACK)
      Curses.init_pair(Curses::COLOR_BLUE, Curses::COLOR_BLACK, Curses::COLOR_BLUE)
      Curses.init_pair(Curses::COLOR_RED, Curses::COLOR_RED, Curses::COLOR_BLACK)
      Curses.init_pair(Curses::COLOR_GREEN, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
    end

    # @param map_filename [String] The filename of a map
    def play(map_filename = nil)
      show_message("Hit Any Key. (Interrupt to exit)")

      if map_filename and File.exists? map_filename
        map = File.readlines map_filename
      else
        map = GridBuilder.new.generate # TODO We should either create a grid or a map but not a mix of both.
      end
      grid = Grid.new map

      while true
        begin
          win = draw grid
          command = command_from_key_combination(win.getch)
          grid.tick(command)
        rescue Interrupt
          break
        ensure
          win.close if win
        end
      end

      Curses.clear
      Curses.refresh
      Curses.close_screen
      puts 'Goodbye...'
    end

    private

    def show_message(message)
      padding = 6
      width = message.length + padding
      win = Curses::Window.new(5, width, (Curses.lines - 5)/2, (Curses.cols - width)/2)
      win.box '|', '-'
      win.setpos 2, 3
      win.addstr message

      win.getch
      win.close
    end

    def draw(grid)
      Curses.doupdate
      win = Curses::Window.new Curses.lines, Curses.cols, 0, 0

      delta_x = (Curses.cols - 2) / 2
      delta_y = (Curses.lines - 2) / 2

      center = grid.player

      grid.all_cells.each do |c|
        next if (center[:x] - c.x).abs > delta_x || (center[:y] - c.y).abs > delta_y
        if c.wall
          add_cell(win, c.x - center[:x] + delta_x, c.y - center[:y] + delta_y, '#', Curses::COLOR_BLACK)
        else
          add_cell(win, c.x - center[:x] + delta_x, c.y - center[:y] + delta_y, '.', Curses::COLOR_BLACK)
        end
      end

      if grid.path
        grid.path.each do |c|
          next if (center[:x] - c.x).abs > delta_x || (center[:y] - c.y).abs > delta_y
          add_cell win, c.x - center[:x] + delta_x, c.y - center[:y] + delta_y, '.', Curses::COLOR_GREEN
        end
      end

      grid.stalkers.each do |c|
        next if (center[:x] - c[:x]).abs > delta_x || (center[:y] - c[:y]).abs > delta_y
        add_cell win, c[:x] - center[:x] + delta_x, c[:y] - center[:y] + delta_y, 's', Curses::COLOR_GREEN
      end

      add_cell win, delta_x, delta_y, '@', Curses::COLOR_RED

      win.refresh

      win
    end

    def add_cell(win, x, y, symbol, color = Curses::COLOR_BLUE)
      win.setpos y, x
      color = Curses.color_pair color
      win.attron(color|Curses::A_NORMAL) {
        win.addstr symbol
      }

      Curses.doupdate
    end

    def command_from_key_combination(key)
      case key
      when ' '
        'player.wait'
      else
        'system.none'
      end
    end
  end
end
