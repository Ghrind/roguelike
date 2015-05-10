require 'spec_helper'

RSpec.describe Roguelike::AStar do
  def coordinates(cell)
    [cell.y, cell.x]
  end
  describe '#find_path' do
    context 'when there is a path' do
      it 'should prefer straight lines over zigzag' do
        grid = grid_from_map ['#####',
                              '#...#',
                              '#...#',
                              '#...#',
                              '#####']

        start = grid.lookup 2, 1
        goal = grid.lookup 2, 3

        astar = Roguelike::AStar.new

        expect(astar.find_path(start, goal).map { |c| coordinates c }).to eq [[2, 1], [2, 2], [2, 3]]
      end

      it 'should use diagonals when needed' do
        grid = grid_from_map ['####',
                              '#..#',
                              '#..#',
                              '####']

        start = grid.lookup 1, 1
        goal = grid.lookup 2, 2

        astar = Roguelike::AStar.new

        expect(astar.find_path(start, goal).map { |c| coordinates c }).to eq [[1, 1], [2, 2]]
      end

      it 'should return all the cells of the path' do
        grid = grid_from_map ['#####',
                              '#...#',
                              '#####']

        start = grid.lookup 1, 1
        goal = grid.lookup 1, 3

        astar = Roguelike::AStar.new

        expect(astar.find_path(start, goal).map { |c| coordinates c }).to eq [[1, 1], [1, 2], [1, 3]]
      end

      it 'should avoid abstacles' do
        grid = grid_from_map ['######',
                              '#....#',
                              '####.#',
                              '#....#',
                              '######']

        start = grid.lookup 1, 1
        goal = grid.lookup 3, 1

        astar = Roguelike::AStar.new

        expect(astar.find_path(start, goal).map { |c| coordinates c }).to eq [[1, 1], [1, 2], [1, 3], [2, 4], [3, 3], [3, 2], [3, 1]]
      end
    end
    context 'when there is no path' do
      it 'should return nil' do
        grid = grid_from_map ['######',
                              '#....#',
                              '######',
                              '#....#',
                              '######']

        start = grid.lookup 1, 1
        goal = grid.lookup 3, 1

        astar = Roguelike::AStar.new

        expect(astar.find_path(start, goal)).to be_nil
      end
    end
  end
end
