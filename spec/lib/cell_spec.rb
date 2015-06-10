require 'spec_helper'

RSpec.describe Roguelike::Cell do
  describe '#on_step_in' do
    let :cell do
      cell = Roguelike::Cell.new 0, 0
      cell.changed = false
      cell
    end
    let :creature do
      Roguelike::Creature.new
    end
    it 'should set the creature of the cell' do
      cell.on_step_in creature
      expect(cell.creature).to eq creature
    end
    context 'when cell is a closed door' do
      before do
        cell.door = true
        cell.open = false
      end
      it 'should open it' do
        cell.on_step_in creature
        expect(cell.open).to eq true
      end
    end
    it 'should marked the cell as changed' do
      cell.on_step_in creature
      expect(cell.changed).to eq true
    end
  end

  describe '#neighbour' do
    context 'when there is a neighbour cell' do
      it 'should return neighbour cell' do
        cell = Roguelike::Cell.new 0, 0
        other_cell = Roguelike::Cell.new 0, -1
        cell.neighbours = [other_cell]
        expect(cell.neighbour(:up)).to eq other_cell
      end
    end
    context 'when there is no neighbour cell' do
      it 'should return nil' do
        cell = Roguelike::Cell.new 0, 0
        expect(cell.neighbour(:up)).to be_nil
      end
    end

    directions = {
      up: [0, -1],
      down: [0, 1],
      left: [-1, 0],
      right: [1, 0],
      up_left: [-1, -1],
      up_right: [1, -1],
      down_left: [-1, 1],
      down_right: [1, 1]
    }
    
    directions.each_pair do |direction, c|
      it "should return the cell at the '#{direction}' position" do
        cell = Roguelike::Cell.new 0, 0
        cell.neighbours = directions.values.map { |c| Roguelike::Cell.new *c }
        expect(cell.neighbour(direction).coordinates.to_a).to eq c
      end
    end
  end

  describe '#on_step_out' do
    it 'should reset the creature of the cell' do
      cell = Roguelike::Cell.new 0, 0
      creature = Roguelike::Creature.new

      cell.on_step_out creature

      expect(cell.creature).to be_nil
    end
  end

  describe '#see_through?' do
    let :cell do
      Roguelike::Cell.new nil, nil
    end
    context 'when cell is a door' do
      before do
        cell.door = true
      end
      context 'when the door is open' do
        before do
          cell.open = true
        end
        it 'should return true' do
          expect(cell).to be_see_through
        end
      end
      context 'when the door is closed' do
        before do
          cell.open = false
        end
        it 'should return false' do
          expect(cell).not_to be_see_through
        end
      end
    end
    context 'when the cell is transparent' do
      before do
        cell.transparent = true
      end
      it 'should return true' do
        expect(cell).to be_see_through
      end
    end
    context 'when the cell is not transparent' do
      before do
        cell.transparent = false
      end
      it 'should return false' do
        expect(cell).not_to be_see_through
      end
    end
  end

  describe '#inspect' do
    before do
      @cell = Roguelike::Cell.new 0, 0, wall: true
    end
    it 'should show the object id' do
      expect(@cell.inspect).to include @cell.object_id.to_s
    end
    it 'should show attributes' do
      expect(@cell.inspect).to include '@wall=true'
    end
    it 'should not show neighbours' do
      expect(@cell.inspect).not_to include '@neighbours'
    end
  end

  describe '.new' do
    it 'should initialize the x attribute' do
      cell = Roguelike::Cell.new 1, nil
      expect(cell.x).to eq 1
    end
    it 'should initialize the y attribute' do
      cell = Roguelike::Cell.new nil, 1
      expect(cell.y).to eq 1
    end
    it 'should initialize the wall attribute' do
      cell = Roguelike::Cell.new nil, nil, wall: true
      expect(cell.wall).to eq true
    end
    it 'should initialize the direction attribute' do
      cell = Roguelike::Cell.new nil, nil, direction: :left
      expect(cell.direction).to eq :left
    end
    it 'should initialize neighbours as an empty array' do
      cell = Roguelike::Cell.new nil, nil
      expect(cell.neighbours).to eq []
    end
  end

  describe '#walkable?' do
    before do
      @cell = Roguelike::Cell.new nil, nil
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
      cell = Roguelike::Cell.new nil, nil
      walkable_cell_1 = Roguelike::Cell.new nil, nil
      walkable_cell_2 = Roguelike::Cell.new nil, nil
      not_walkable_cell_1 = Roguelike::Cell.new nil, nil
      not_walkable_cell_2 = Roguelike::Cell.new nil, nil

      cell.neighbours = [not_walkable_cell_1, walkable_cell_1, not_walkable_cell_2, walkable_cell_2]

      expect(walkable_cell_1).to receive(:walkable?).and_return true
      expect(walkable_cell_2).to receive(:walkable?).and_return true
      expect(not_walkable_cell_1).to receive(:walkable?).and_return false
      expect(not_walkable_cell_2).to receive(:walkable?).and_return false

      expect(cell.walkable_neighbours).to eq [walkable_cell_1, walkable_cell_2]
    end
  end

  describe '#open!' do
    let :cell do
      cell = Roguelike::Cell.new nil, nil
      cell.changed = false
      cell
    end
    context 'when cell is not a door' do
      it 'should return false' do
        expect(cell.open!).to eq false
      end
      it 'should not mark the door as changed' do
        cell.open!
        expect(cell.changed).to eq false
      end
    end
    context 'when cell is a door' do
      before do
        cell.door = true
      end
      context 'when it is closed' do
        before do
          cell.open = false
        end
        it 'should open the door' do
          cell.open!
          expect(cell.open).to eq true
        end
        it 'should mark the door as changed' do
          cell.open!
          expect(cell.changed).to eq true
        end
        it 'should return true' do
          expect(cell.open!).to eq true
        end
      end
      context 'when it is open' do
        before do
          cell.open = true
        end
        it 'should return false' do
          expect(cell.open!).to eq false
        end
        it 'should not mark the door as changed' do
          cell.open!
          expect(cell.changed).to eq false
        end
      end
    end
  end

  describe '#close!' do
    let :cell do
      cell = Roguelike::Cell.new nil, nil
      cell.changed = false
      cell
    end
    context 'when cell is not a door' do
      it 'should return false' do
        expect(cell.close!).to eq false
      end
      it 'should not mark the door as changed' do
        cell.close!
        expect(cell.changed).to eq false
      end
    end
    context 'when cell is a door' do
      before do
        cell.door = true
      end
      context 'when it is open' do
        before do
          cell.open = true
        end
        it 'should close the door' do
          cell.close!
          expect(cell.open).to eq false
        end
        it 'should mark the door as changed' do
          cell.close!
          expect(cell.changed).to eq true
        end
        it 'should return true' do
          expect(cell.close!).to eq true
        end
      end
      context 'when it is closed' do
        before do
          cell.open = false
        end
        it 'should return false' do
          expect(cell.close!).to eq false
        end
        it 'should not mark the door as changed' do
          cell.close!
          expect(cell.changed).to eq false
        end
      end
    end
  end
end
