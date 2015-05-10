module Roguelike
  # An implementation of the A* algorithm.
  # Initially taken from http://branch14.org/snippets/a_star_in_ruby.html and fixed
  class AStar
    def find_path(start, goal)
      been_there = {}
      pqueue = PriorityQueue.new
      pqueue << [1, [start, [], 0]]
      while !pqueue.empty?
        spot, path_so_far, cost_so_far = pqueue.next
        next if been_there[spot]
        newpath = path_so_far + [spot]
        return newpath if (spot == goal)
        been_there[spot] = 1
        adjacent_cells(spot).each do |newspot|
          next if been_there[newspot]
          tcost = cost(spot, newspot)
          next unless tcost
          newcost = cost_so_far + tcost
          pqueue << [newcost + distance(goal, newspot),
                     [newspot, newpath, newcost]]
        end
      end
      return nil
    end

    private

    # @param cell [Cell] Any cell of the grid
    # @return [Array<Cell>] Every walkable cells adjacent to the given cell.
    def adjacent_cells(cell)
      cell.walkable_neighbours
    end

    # @param cell [Cell] The starting cell
    # @param other [Cell] A neighbour of the cell
    # @return [Fixnum] The cost of going from a cell to another
    def cost(cell, other_cell)
      # The diagonals cost more in order to avoid zigzaging
      return 10 if cell.x > other_cell.x && cell.y == other_cell.y
      return 10 if cell.x < other_cell.x && cell.y == other_cell.y
      return 10 if cell.y > other_cell.y && cell.x == other_cell.x
      return 10 if cell.y < other_cell.y && cell.x == other_cell.x
      14
    end

    # @param cell [Cell] The starting cell
    # @param other [Cell] Another cell of the grid
    # @return [Float] The euclidian distance between two cells.
    def distance(cell, other_cell)
      Math.sqrt((cell.x - other_cell.x)**2 + (cell.y - other_cell.y)**2)
    end

    class PriorityQueue
      def initialize
        @list = []
      end
      def add(priority, item)
        @list << [priority, @list.length, item]
        @list.sort_by!{|a| a.first}
      end
      def <<(pritem)
        add(*pritem)
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
