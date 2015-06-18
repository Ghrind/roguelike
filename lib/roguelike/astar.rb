module Roguelike
  # An implementation of the A* algorithm.
  # Initially taken from http://branch14.org/snippets/a_star_in_ruby.html and fixed
  class AStar
    def find_path(start, goal, assume_goal_is_free = false)
      been_there = {}
      pqueue = PriorityQueue.new
      pqueue.add 1, [start, [], 0]
      free_goal = assume_goal_is_free ? goal : nil
      while !pqueue.empty?
        spot, path_so_far, cost_so_far = pqueue.next
        next if been_there[spot]
        newpath = path_so_far + [spot]
        return newpath if spot == goal
        been_there[spot] = true
        adjacent_cells(spot, free_goal).each do |newspot|
          next if been_there[newspot]
          tcost = cost(spot, newspot)
          newcost = cost_so_far + tcost
          pqueue.add newcost + distance(goal, newspot), [newspot, newpath, newcost]
        end
      end
      return nil
    end

    private

    # @param cell [Cell] Any cell of the grid
    # @return [Array<Cell>] Every walkable cells adjacent to the given cell.
    def adjacent_cells(cell, goal)
      cell.neighbours.select { |n| n == goal || n.walkable_when_free? }
    end

    # @param cell [Cell] The starting cell
    # @param other [Cell] A neighbour of the cell
    # @return [Fixnum] The cost of going from a cell to another
    def cost(cell, other_cell)
      c = 14
      # The diagonals cost more in order to avoid zigzaging
      c = 10 if cell.x > other_cell.x && cell.y == other_cell.y
      c = 10 if cell.x < other_cell.x && cell.y == other_cell.y
      c = 10 if cell.y > other_cell.y && cell.x == other_cell.x
      c = 10 if cell.y < other_cell.y && cell.x == other_cell.x
      cell.creature ? c + 10 : c
    end

    # @param cell [Cell] The starting cell
    # @param other [Cell] Another cell of the grid
    # @return [Float] The manhattan distance between two cells.
    def distance(cell, other_cell)
      (cell.x - other_cell.x).abs + (cell.y - other_cell.y).abs
    end

    class PriorityQueue
      def initialize
        @list = []
      end
      def add(priority, item)
        index = @list.index { |e| e.first >= priority }
        @list.insert(index || @list.size, [priority, @list.length, item])
      end
      def next
        @list.shift[2]
      end
      def empty?
        @list.empty?
      end
    end
  end
end
