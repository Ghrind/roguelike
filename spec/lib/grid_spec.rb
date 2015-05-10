require 'spec_helper'

RSpec.describe Roguelike::Grid do
  describe '.new' do
    it 'should assign neighbours to each cell' do
      grid = Roguelike::Grid.new ['###',
                                  '#.#',
                                  '###']

      floor_cell = grid.lookup(1, 1)
      expect(floor_cell.neighbours.size).to eq 8
      floor_cell.neighbours.each do |cell|
        expect(cell).not_to be_walkable
      end
    end

    it "should change @ into the player's starting point" do
      grid = Roguelike::Grid.new ['@']
      cell = grid.lookup(0, 0)
      expect(cell).to be_walkable
      expect(grid.player).to eq({ x: 0, y: 0 })
    end

    it "should change > into the player's destination" do
      grid = Roguelike::Grid.new ['>']
      cell = grid.lookup(0, 0)
      expect(cell).to be_walkable
      expect(grid.destination).to eq cell
    end

    it 'should change # into a wall' do
      grid = Roguelike::Grid.new ['#']
      cell = grid.lookup(0, 0)
      expect(cell).not_to be_walkable
    end

    it 'should change . into floor' do
      grid = Roguelike::Grid.new ['.']
      cell = grid.lookup(0, 0)
      expect(cell).to be_walkable
    end

    it 'should change ! into a stalker' do
      grid = Roguelike::Grid.new ['!']
      cell = grid.lookup(0, 0)
      expect(cell).to be_walkable
      expect(grid.stalkers.size).to eq 1
      expect(grid.stalkers.first).to eq({ x: 0, y: 0 })
    end

    it 'should ignore other characters' do
      grid = Roguelike::Grid.new [' ']
      expect(grid.all_cells).to be_empty
    end
  end

  describe '#all_cells' do
    it 'should contain all cells' do
      grid = Roguelike::Grid.new ['###',
                                  '#.#',
                                  '###']

      expect(grid.all_cells.size).to eq 9
    end
  end

  describe '#cells' do
    it 'should contain all cells in a grid' do
      grid = Roguelike::Grid.new ['###',
                                  '#.#',
                                  '#.#',
                                  '###']

      expect(grid.cells.size).to eq 4
      grid.cells.each do |row|
        expect(row.size).to eq 3
      end
    end
  end

  describe '#lookup' do
    context 'when there is a cell at position' do
      it 'should return cell at position' do
        grid = Roguelike::Grid.new ['...',
                                    '..#']

        expect(grid.lookup(1, 2)).not_to be_walkable
      end
    end
    context 'when there is no cell at position' do
      it 'should raise an error' do
        grid = Roguelike::Grid.new ['...',
                                    '..#']

        expect do
          grid.lookup(2, 2)
        end.to raise_error Roguelike::Grid::PositionOutOfBoundError

        expect do
          grid.lookup(1, 3)
        end.to raise_error Roguelike::Grid::PositionOutOfBoundError
      end
    end
  end
end
