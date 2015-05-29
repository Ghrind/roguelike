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

      @target = { x: 0, y: 0 }
    end

    # @param map_filename [String] The filename of a map
    def play(map_filename = nil)
      show_message("Hit Any Key. (Interrupt to exit)")

      if map_filename and File.exists? map_filename
        map = File.readlines map_filename
        @grid = Grid.new_from_map map
      else
        @grid = GridBuilder.new.generate
      end

      win = draw @grid
      redraw = false
      begin
        while true
          if redraw
            win = draw @grid
          end
          redraw = command_from_key_combination(win.getch)
        end
      rescue Interrupt
        
      ensure
        win.del if win
        Ncurses.echo
        Ncurses.nl
        Ncurses.endwin
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

      delta_y = (Ncurses.LINES - 2) / 2
      delta_x = (Ncurses.COLS - 2) / 2

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
      add_cell win, @target[:x] - center[:x] + delta_x, @target[:y] - center[:y] + delta_y, '+', Ncurses::COLOR_RED

      win.color_set Ncurses::COLOR_WHITE, nil
      win.mvaddstr 1, 1, "x: #{grid.player[:x]} y: #{grid.player[:y]}"
      win.mvaddstr 2, 1, "x: #{@target[:x]} y: #{@target[:y]}"

      win
    end

    def add_cell(win, x, y, symbol, color)
      win.color_set color, nil
      win.mvaddstr y, x, symbol
    end

    # @return [Boolean] Should the grid be redrawn
    def command_from_key_combination(key)
      case key
      when 65 # Up arrow
      when 122 # a
        # 'target.move_up'
        @target[:y] -= 1
        true
      when 66 # Down arrow
      when 115 # s
        # 'target.move_down'
        @target[:y] += 1
        true
      when 67 # Right arrow
      when 100 # d
        # 'target.move_right'
        @target[:x] += 1
        true
      when 68 # Left arrow
      when 113 # q
        # 'target.move_left'
        @target[:x] -= 1
        true
      when 99 # c
        # 'target.center'
        @target[:x] = @grid.player[:x]
        @target[:y] = @grid.player[:y]
        true
      when 32 # Space
        @grid.tick 'player.wait'
        true
      else
        # 'system.none'
        show_message "Unknown key with code: #{key}"
        false
      end
    end
  end
end
