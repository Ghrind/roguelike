require 'spec_helper'

RSpec.describe Roguelike::GridBuilder do
  before do
    @grid = Roguelike::Grid.new
    expect(Roguelike::Grid).to receive(:new).and_return @grid
    @builder = Roguelike::GridBuilder.new width: 1, height: 1
  end
  describe '#cell_available?' do
    context 'when the cell is occupied' do
      it 'should return false' do
        @grid.add_cell Roguelike::Cell.new(0, 0)
        expect(@builder.cell_available? 0, 0).to eq false
      end
    end
    context 'when the cell is out of the grid boundaries' do
      it 'should return false' do
        expect(@builder.cell_available? 1, 0).to eq false
        expect(@builder.cell_available? 0, 1).to eq false
        expect(@builder.cell_available? 0, -1).to eq false
        expect(@builder.cell_available? -1, 0).to eq false
      end
    end
    context 'when the cell is a wall' do
      it 'should return true' do
        @grid.add_cell Roguelike::Cell.new(0, 0, wall: true)
        expect(@builder.cell_available? 0, 0).to eq true
      end
    end
    context 'when there is nothing at the position of the cell' do
      it 'should return true' do
        expect(@builder.cell_available? 0, 0).to eq true
      end
    end
  end
end
