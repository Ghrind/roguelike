require 'ncursesw'
require_relative 'level'
require_relative 'creature'

module Roguelike
  class Game
    def initialize
      Ncurses.initscr
      Ncurses.cbreak
      Ncurses.curs_set 0
      Ncurses.noecho
      Ncurses.start_color

      Ncurses.init_pair(Ncurses::COLOR_BLACK, Ncurses::COLOR_BLACK, Ncurses::COLOR_BLACK)
      Ncurses.init_pair(Ncurses::COLOR_RED, Ncurses::COLOR_RED, Ncurses::COLOR_BLACK)
      Ncurses.init_pair(Ncurses::COLOR_GREEN, Ncurses::COLOR_GREEN, Ncurses::COLOR_BLACK)
      Ncurses.init_pair(Ncurses::COLOR_WHITE, Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK)

      @target = { x: 0, y: 0 }
      @player = nil
    end

    # @param map_filename [String] The filename of a map
    def play(map_filename = nil)
      show_message("Hit Any Key. (Interrupt to exit)")

      # TODO
      #if map_filename and File.exists? map_filename
      #  map = File.readlines map_filename
      #  @level = Grid.new_from_map map
      #else
        @level = LevelBuilder.new.generate
      #end

      @player = Roguelike::Creature.new symbol: '@', light_radius: 5
      start = @level.cells.find_all { |c| c.start }.sample
      @level.enter @player, start

      win = draw @level
      redraw = false
      begin
        while true
          if redraw
            win = draw @level
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

    def draw(level)
      level.do_fov @player
      win = Ncurses::WINDOW.new Ncurses.LINES, Ncurses.COLS, 0, 0
      win.border *([0]*8)

      delta_y = (Ncurses.LINES - 2) / 2
      delta_x = (Ncurses.COLS - 2) / 2

      center = @player

      level.cells.each do |c|
        next if (center.x - c.x).abs > delta_x || (center.y - c.y).abs > delta_y
        next unless center.visited?(c)
        color = center.in_sight?(c) ? Ncurses::COLOR_GREEN : Ncurses::COLOR_BLACK
        x = c.x - center.x + delta_x
        y = c.y - center.y + delta_y
        add_cell(win, x, y, c.symbol, color)
        if c.creature
          add_cell win, x, y, c.creature.symbol, color
        end
      end

      #level.stalkers.each do |c|
      #  next if (center[:x] - c[:x]).abs > delta_x || (center[:y] - c[:y]).abs > delta_y
      #  add_cell win, c[:x] - center[:x] + delta_x, c[:y] - center[:y] + delta_y, '!', Ncurses::COLOR_GREEN
      #end

      #add_cell win, delta_x, delta_y, '@', Ncurses::COLOR_RED
      add_cell win, @target[:x] - center.x + delta_x, @target[:y] - center.y + delta_y, '+', Ncurses::COLOR_RED

      win.color_set Ncurses::COLOR_WHITE, nil
      win.mvaddstr 1, 1, "x: #{@player.x} y: #{@player.y}"
      win.mvaddstr 2, 1, "x: #{@target[:x]} y: #{@target[:y]}"

      win
    end

    def add_cell(win, x, y, symbol, color)
      win.color_set color, nil
      win.mvaddstr y, x, symbol
    end

    def tick(command)
      case command
      when 'player.wait'
      when /^player\.move_/
        direction = command.sub('player.move_', '').to_sym
        if @level.creature_can_move?(@player, direction)
          @level.move_creature(@player, direction)
        else
          # TODO Try another action on the cell
        end
      else
        return
      end

      #@stalkers.each do |s|
      #  start = lookup(s[:x], s[:y])
      #  dest = lookup(@player.x, @player.y)
      #  next if start == dest
      #  path = astar.find_path(start, dest)
      #  if path
      #    s[:x] = path[1].x
      #    s[:y] = path[1].y
      #  end
      #end

      true
    end

    # @return [Boolean] Should the level be redrawn
    def command_from_key_combination(key)
      #when 65 # Up arrow
      #when 122 # a
      #when 66 # Down arrow
      #when 115 # s
      #when 67 # Right arrow
      #when 100 # d
      #when 68 # Left arrow
      #when 113 # q
      case key
      when 56 # Numpad 8
        tick 'player.move_up'
      when 57 # Numpad 9
        tick 'player.move_up_right'
      when 54 # Numpad 6
        tick 'player.move_right'
      when 51 # Numpad 3
        tick 'player.move_down_right'
      when 50 # Numpad 2
        tick 'player.move_down'
      when 49 # Numpad 1
        tick 'player.move_down_left'
      when 52 # Numpad 4
        tick 'player.move_left'
      when 55 # Numpad 7
        tick 'player.move_up_left'
      when 32 # Space
        tick 'player.wait'
      when 111 # o
        # 'target.move_up'
        @target[:y] -= 1
        true
      when 108 # l
        # 'target.move_down'
        @target[:y] += 1
        true
      when 109 # m
        # 'target.move_right'
        @target[:x] += 1
        true
      when 107 # k
        # 'target.move_left'
        @target[:x] -= 1
        true
      when 99 # c
        # 'target.center'
        @target[:x] = @player.x
        @target[:y] = @player.y
        true
      else
        # 'system.none'
        show_message "Unknown key with code: #{key}"
        false
      end
    end
  end
end
