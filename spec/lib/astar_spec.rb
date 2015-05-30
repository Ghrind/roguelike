require 'spec_helper'

RSpec.describe Roguelike::AStar do
  def coordinates(cell)
    [cell.y, cell.x]
  end

  describe '#find_path' do
    context 'when there is a path' do
      it 'should prefer straight lines over zigzag' do
        level = level_from_map ['#####',
                                '#...#',
                                '#...#',
                                '#...#',
                                '#####']

        start = level.lookup 1, 2
        goal = level.lookup 3, 2

        astar = Roguelike::AStar.new

        expect(astar.find_path(start, goal).map { |c| coordinates c }).to eq [[2, 1], [2, 2], [2, 3]]
      end

      it 'should use diagonals when needed' do
        level = level_from_map ['####',
                                '#..#',
                                '#..#',
                                '####']

        start = level.lookup 1, 1
        goal = level.lookup 2, 2

        astar = Roguelike::AStar.new

        expect(astar.find_path(start, goal).map { |c| coordinates c }).to eq [[1, 1], [2, 2]]
      end

      it 'should return all the cells of the path' do
        level = level_from_map ['#####',
                                '#...#',
                                '#####']

        start = level.lookup 1, 1
        goal = level.lookup 3, 1

        astar = Roguelike::AStar.new

        expect(astar.find_path(start, goal).map { |c| coordinates c }).to eq [[1, 1], [1, 2], [1, 3]]
      end

      it 'should avoid abstacles' do
        level = level_from_map ['######',
                                '#....#',
                                '####.#',
                                '#....#',
                                '######']

        start = level.lookup 1, 1
        goal = level.lookup 1, 3

        astar = Roguelike::AStar.new

        expect(astar.find_path(start, goal).map { |c| coordinates c }).to eq [[1, 1], [1, 2], [1, 3], [2, 4], [3, 3], [3, 2], [3, 1]]
      end
    end
    context 'when there is no path' do
      it 'should return nil' do
        level = level_from_map ['######',
                                '#....#',
                                '######',
                                '#....#',
                                '######']

        start = level.lookup 1, 1
        goal = level.lookup 1, 3

        astar = Roguelike::AStar.new

        expect(astar.find_path(start, goal)).to be_nil
      end
    end
  end
end
