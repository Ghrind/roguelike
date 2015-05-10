require 'spec_helper'

RSpec.describe Roguelike::Cell do
  describe '.new' do
    it 'should initialize x attribute' do
      cell = Roguelike::Cell.new 1, nil, nil
      expect(cell.x).to eq 1
    end
    it 'should initialize y attribute' do
      cell = Roguelike::Cell.new nil, 1, nil
      expect(cell.y).to eq 1
    end
    it 'should initialize wall attribute' do
      cell = Roguelike::Cell.new nil, nil, true
      expect(cell.wall).to eq true
    end
    it 'should initialize neighbours as an empty array' do
      cell = Roguelike::Cell.new nil, nil, nil
      expect(cell.neighbours).to eq []
    end
  end

  describe '#walkable?' do
    before do
      @cell = Roguelike::Cell.new nil, nil, nil
    end
    context 'when the cell is a wall' do
      before do
        @cell.instance_variable_set :@wall, true
      end
      it 'should not be walkable' do
        expect(@cell).not_to be_walkable
      end
    end
    context 'when the cell is not a wall' do
      before do
        @cell.instance_variable_set :@wall, false
      end
      it 'should be walkable' do
        expect(@cell).to be_walkable
      end
    end
  end

  describe '#walkable_neighbours' do
    it 'should return all neighbours that are walkable' do
      cell = Roguelike::Cell.new nil, nil, nil
      walkable_cell_1 = Roguelike::Cell.new nil, nil, nil
      walkable_cell_2 = Roguelike::Cell.new nil, nil, nil
      not_walkable_cell_1 = Roguelike::Cell.new nil, nil, nil
      not_walkable_cell_2 = Roguelike::Cell.new nil, nil, nil

      cell.neighbours = [not_walkable_cell_1, walkable_cell_1, not_walkable_cell_2, walkable_cell_2]

      expect(walkable_cell_1).to receive(:walkable?).and_return true
      expect(walkable_cell_2).to receive(:walkable?).and_return true
      expect(not_walkable_cell_1).to receive(:walkable?).and_return false
      expect(not_walkable_cell_2).to receive(:walkable?).and_return false

      expect(cell.walkable_neighbours).to eq [walkable_cell_1, walkable_cell_2]
    end
  end
end
