require 'ncursesw'
require_relative 'grid'

module Roguelike
  # Inspired by https://github.com/aka-bo/ruby-curses-conway
  class Game
    def initialize
      Ncurses.initscr
      Ncurses.cbreak
      Ncurses.curs_set 0
      Ncurses.noecho
      Ncurses.start_color

      # enable arrow keys (required for pageup/down)
      # Ncurses.keypad(scr, true) 

      Ncurses.init_pair(Ncurses::COLOR_BLACK, Ncurses::COLOR_BLACK, Ncurses::COLOR_BLACK)
      Ncurses.init_pair(Ncurses::COLOR_RED, Ncurses::COLOR_RED, Ncurses::COLOR_BLACK)
      Ncurses.init_pair(Ncurses::COLOR_GREEN, Ncurses::COLOR_GREEN, Ncurses::COLOR_BLACK)
      Ncurses.init_pair(Ncurses::COLOR_WHITE, Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK)
    end

    # @param map_filename [String] The filename of a map
    def play(map_filename = nil)
      show_message("Hit Any Key. (Interrupt to exit)")

      if map_filename and File.exists? map_filename
        map = File.readlines map_filename
        grid = Grid.new_from_map map
      else
        grid = GridBuilder.new.generate
      end

      while true
        begin
          # TODO redraw only if something happened
          win = draw grid
          command = command_from_key_combination(win.getch)
          grid.tick(command)
        rescue Interrupt
          break
        ensure
          win.del if win
          Ncurses.echo
          Ncurses.nl
          Ncurses.endwin
        end
      end


      puts 'Goodbye...'
    end

    private

    def show_message(message)
      padding = 6
      width = message.length + padding
      win = Ncurses::WINDOW.new(5, width, (Ncurses.LINES - 5)/2, (Ncurses.COLS - width)/2)
      win.border *([0]*8)
      win.mvaddstr 2, 3, message

      win.getch
      win.del
    end

    def draw(grid)
      win = Ncurses::WINDOW.new Ncurses.LINES, Ncurses.COLS, 0, 0
      win.border *([0]*8)

      delta_x = (Ncurses.LINES - 2) / 2
      delta_y = (Ncurses.COLS - 2) / 2

      center = grid.player

      grid.all_cells.each do |c|
        next if (center[:x] - c.x).abs > delta_x || (center[:y] - c.y).abs > delta_y
        if c.wall
          add_cell(win, c.x - center[:x] + delta_x, c.y - center[:y] + delta_y, '#', Ncurses::COLOR_BLACK)
        else
          add_cell(win, c.x - center[:x] + delta_x, c.y - center[:y] + delta_y, '.', Ncurses::COLOR_BLACK)
        end
      end

      if grid.path
        grid.path.each do |c|
          next if (center[:x] - c.x).abs > delta_x || (center[:y] - c.y).abs > delta_y
          add_cell win, c.x - center[:x] + delta_x, c.y - center[:y] + delta_y, '.', Ncurses::COLOR_GREEN
        end
      end

      grid.stalkers.each do |c|
        next if (center[:x] - c[:x]).abs > delta_x || (center[:y] - c[:y]).abs > delta_y
        add_cell win, c[:x] - center[:x] + delta_x, c[:y] - center[:y] + delta_y, 's', Ncurses::COLOR_GREEN
      end

      add_cell win, delta_x, delta_y, '@', Ncurses::COLOR_RED

      win.color_set Ncurses::COLOR_WHITE, nil
      win.mvaddstr 1, 1, "x: #{grid.player[:x]} y: #{grid.player[:y]}"

      win
    end

    def add_cell(win, x, y, symbol, color)
      win.color_set color, nil
      win.mvaddstr x, y, symbol
    end

    def command_from_key_combination(key)
      case key.chr
      when ' '
        'player.wait'
      else
        'system.none'
      end
    end
  end
end
