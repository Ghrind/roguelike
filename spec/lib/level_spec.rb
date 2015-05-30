require 'spec_helper'

RSpec.describe Roguelike::Level do
  let(:feature_1) {
    feature_from_map [
      '###',
      '#.#',
      '###'
    ]
  }

  describe '#set_cells' do
    before do
      @level = Roguelike::Level.new
      @level.set_cells feature_1
    end
    it 'should set grid' do
      expect(@level.grid).to eq feature_1.grid
    end
    it 'should set cells collection' do
      expect(@level.cells).to eq feature_1.cells
    end
    it 'should assign neighbours to each cell' do
      floor_cell = @level.lookup(1, 1)
      expect(floor_cell.neighbours.size).to eq 8
      floor_cell.neighbours.each do |cell|
        expect(cell.wall).to eq true
      end
    end
    it 'should remove previous cells' do
      @level.set_cells feature_1
      expect(@level.cells).to eq feature_1.cells
    end
  end

  describe '#lookup' do
    before do
      @level = Roguelike::Level.new
      @level.set_cells feature_1
    end
    context 'when there is a cell at position' do
      it 'should return cell at position' do
        cell = @level.lookup(1, 2)
        expect(cell.x).to eq 1
        expect(cell.y).to eq 2
      end
    end
    context 'when there is no cell at position' do
      it 'should return nil' do
        expect(@level.lookup(4, 2)).to be_nil
        expect(@level.lookup(1, 3)).to be_nil
      end
    end
  end

  describe '#reset!' do
    it 'should clear all cells' do
      level = Roguelike::Level.new
      level.set_cells feature_1

      level.reset!
      expect(level.cells).to be_nil
      expect(level.grid).to be_nil
    end
  end
end
