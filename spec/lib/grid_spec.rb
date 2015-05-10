require 'spec_helper'

RSpec.describe Roguelike::Grid do
  describe '#prepare!' do
    it 'should assign neighbours to each cell' do
      # A 3x3 grid with a single floor on its center
      grid = Roguelike::Grid.new
      [[0, 0], [0, 1], [0, 2], [1, 0], [1, 2], [2, 0], [2, 1], [2, 2]].each do |x, y|
        grid.add_cell Roguelike::Cell.new(x, y, wall: true)
      end
      grid.add_cell Roguelike::Cell.new(1, 1)

      grid.prepare!

      floor_cell = grid.lookup(1, 1)
      expect(floor_cell.neighbours.size).to eq 8
      floor_cell.neighbours.each do |cell|
        expect(cell).not_to be_walkable
      end
    end
  end

  describe '.new_from_map' do
    it "should change @ into the player's starting point" do
      grid = grid_from_map ['@']
      cell = grid.lookup(0, 0)
      expect(cell).to be_walkable
      expect(grid.player).to eq({ x: 0, y: 0 })
    end

    it "should change > into the player's destination" do
      grid = grid_from_map ['>']
      cell = grid.lookup(0, 0)
      expect(cell).to be_walkable
      expect(grid.destination).to eq cell
    end

    it 'should change # into a wall' do
      grid = grid_from_map ['#']
      cell = grid.lookup(0, 0)
      expect(cell).not_to be_walkable
    end

    it 'should change . into floor' do
      grid = grid_from_map ['.']
      cell = grid.lookup(0, 0)
      expect(cell).to be_walkable
    end

    it 'should change ! into a stalker' do
      grid = grid_from_map ['!']
      cell = grid.lookup(0, 0)
      expect(cell).to be_walkable
      expect(grid.stalkers.size).to eq 1
      expect(grid.stalkers.first).to eq({ x: 0, y: 0 })
    end

    it 'should ignore other characters' do
      grid = grid_from_map [' ']
      expect(grid.all_cells).to be_empty
    end
  end

  describe '#all_cells' do
    it 'should contain all cells' do
      grid = grid_from_map ['###',
                            '#.#',
                            '###']

      expect(grid.all_cells.size).to eq 9
    end
  end

  describe '#cells' do
    it 'should contain all cells in a grid' do
      grid = grid_from_map ['###',
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
        grid = grid_from_map ['...',
                              '..#']

        expect(grid.lookup(1, 2)).not_to be_walkable
      end
    end
    context 'when there is no cell at position' do
      it 'should return nil' do
        grid = grid_from_map ['...',
                              '..#']

        expect(grid.lookup(2, 2)).to be_nil
        expect(grid.lookup(1, 3)).to be_nil
      end
    end
  end

  describe '#add_cell' do
    before do
      @grid = grid_from_map ['.']
    end
    context 'when the overwrite option is false' do
      context 'when the cell is occupied' do
        it 'should raise an error' do
          expect do
            @grid.add_cell Roguelike::Cell.new(0, 0)
          end.to raise_error Roguelike::Grid::CellNotAvailableError
        end
      end
      context 'when the cell is free' do
        it 'should add cell to @cells' do
          cell = Roguelike::Cell.new(1, 0)
          @grid.add_cell cell
          expect(@grid.cells[0][1]).to eq cell
        end
        it 'should add cell to @all_cells' do
          cell = Roguelike::Cell.new(1, 0)
          @grid.add_cell cell
          expect(@grid.all_cells.last).to eq cell
        end
      end
    end
    context 'when the overwrite option is true' do
      context 'when the cell is occupied' do
        it 'should replace cell' do
          cell = Roguelike::Cell.new(0, 0)
          @grid.add_cell cell, true
          expect(@grid.all_cells.last).to eq cell
          expect(@grid.cells[0][0]).to eq cell
          expect(@grid.all_cells.size).to eq 1
        end
      end
    end
  end
  
  describe '#cell_available?' do
    before do
      @grid = grid_from_map ['.']
    end
    context 'when there is a cell at the same position' do
      it 'should return false' do
        expect(@grid.cell_available?(0, 0)).to eq false
      end
    end
    context 'when there is no cell at position' do
      it 'should return true' do
        expect(@grid.cell_available?(1, 0)).to eq true
      end
    end
  end

  describe '#reset!' do
    it 'should clear all cells' do
      grid = grid_from_map ['###',
                            '#.#',
                            '###']

      grid.reset!
      expect(grid.all_cells).to be_empty
      expect(grid.cells).to be_empty
    end
  end
end
