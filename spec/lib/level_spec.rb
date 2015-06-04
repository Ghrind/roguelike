require 'spec_helper'

RSpec.describe Roguelike::Level do
  let(:feature_1) {
    feature_from_map [
      '###',
      '#.#',
      '###'
    ]
  }

  let(:level_1) {
    level = Roguelike::Level.new
    level.set_cells feature_1
    level
  }

  let(:feature_2) {
    feature_from_map [
      '#####',
      '#...#',
      '#...#',
      '#...#',
      '#####'
    ]
  }

  let(:level_2) {
    level = Roguelike::Level.new
    level.set_cells feature_2
    level
  }

  describe '#creature_movement' do
    before do
      @creature = Roguelike::Creature.new x: 1, y: 2
    end
    it 'should return start' do
      expect(level_2.creature_movement(@creature, :up).first).to eq level_2.lookup(1, 2)
    end
    it 'should return destination' do
      expect(level_2.creature_movement(@creature, :up).last).to eq level_2.lookup(1, 1)
    end
  end

  describe '#destination_reachable?' do
    context 'when destination is nil' do
      it 'should return false' do
        destination = level_2.lookup 20000, 55000
        expect(level_2.destination_reachable?(destination)).to eq false
      end
    end
    context 'when destination is walkable' do
      it 'should return true' do
        destination = level_2.lookup 2, 1
        expect(level_2.destination_reachable?(destination)).to eq true
      end
    end
    context 'when destination is not walkable' do
      it 'should return false' do
        destination = level_2.lookup 0, 2
        expect(level_2.destination_reachable?(destination)).to eq false
      end
    end
  end

  describe '#creature_can_move?' do
    before do
      @creature = Roguelike::Creature.new x: 1, y: 2
    end
    context 'when the destination is reachable' do
      it 'should return true' do
        destination = level_2.lookup(1, 1)
        expect(level_2).to receive(:destination_reachable?).with(destination).and_return true
        expect(level_2.creature_can_move?(@creature, :up)).to eq true
      end
    end
    context 'when the destination is not reachable' do
      it 'should return false' do
        destination = level_2.lookup(0, 2)
        expect(level_2).to receive(:destination_reachable?).with(destination).and_return false
        expect(level_2.creature_can_move?(@creature, :left)).to eq false
      end
    end
  end

  describe '#move_creature' do
    before do
      @creature = Roguelike::Creature.new x: 1, y: 2
    end
    it 'should make the creature step out of the start cell' do
      start = level_2.lookup 1, 2
      expect(@creature).to receive(:step_out).with(start)
      level_2.move_creature @creature, :up
    end
    it 'should mage the creature step in the destination cell' do
      destination = level_2.lookup 1, 1
      expect(@creature).to receive(:step_in).with(destination)
      level_2.move_creature @creature, :up
    end
  end

  describe '#blocked' do
    before do
      @level = Roguelike::Level.new
      @cell = Roguelike::Cell.new 1, 5
      expect(@level).to receive(:lookup).with(1, 5).and_return(@cell)
    end
    context 'when creatures can see through cell' do
      before do
        expect(@cell).to receive(:see_through?).and_return(true)
      end
      it 'should return false' do
        expect(@level.blocked?(1, 5)).to eq false
      end
    end
    context 'when creatures cannot see through cell' do
      before do
        expect(@cell).to receive(:see_through?).and_return(false)
      end
      it 'should return true' do
        expect(@level.blocked?(1, 5)).to eq true
      end
    end
  end

  describe '#enter' do
    before do
      @creature = Roguelike::Creature.new
    end
    it 'should make the creature step in the start cell' do
      start_cell = level_1.lookup(1, 1)
      expect(@creature).to receive(:step_in).with(start_cell)
      level_1.enter @creature, start_cell
    end
  end

  describe '#light' do
    before do
      @creature = Roguelike::Creature.new
    end
    it "should add cell to the creature's fov" do
      cell = level_1.lookup 1, 2
      level_1.light(@creature, cell.x, cell.y)
      expect(@creature.fov).to include(cell)
    end
    it 'should make the creature visit the cell' do
      cell = level_1.lookup 1, 2
      expect(@creature).to receive(:visit).with(cell)
      level_1.light(@creature, cell.x, cell.y)
    end
  end

  describe '#set_cells' do
    it 'should set grid' do
      expect(level_1.grid).to eq feature_1.grid
    end
    it 'should set cells collection' do
      expect(level_1.cells).to eq feature_1.cells
    end
    it 'should assign neighbours to each cell' do
      floor_cell = level_1.lookup(1, 1)
      expect(floor_cell.neighbours.size).to eq 8
      floor_cell.neighbours.each do |cell|
        expect(cell.wall).to eq true
      end
    end
    it 'should remove previous cells' do
      level_1.set_cells feature_1
      expect(level_1.cells).to eq feature_1.cells
    end
  end

  describe '#lookup' do
    context 'when there is a cell at position' do
      it 'should return cell at position' do
        cell = level_1.lookup(1, 2)
        expect(cell.x).to eq 1
        expect(cell.y).to eq 2
      end
    end
    context 'when there is no cell at position' do
      it 'should return nil' do
        expect(level_1.lookup(4, 2)).to be_nil
        expect(level_1.lookup(1, 3)).to be_nil
      end
    end
  end

  describe '#reset!' do
    it 'should clear all cells' do
      level_1.reset!
      expect(level_1.cells).to be_nil
      expect(level_1.grid).to be_nil
    end
  end

  describe '#get_path' do
    it 'should return a path' do
      start = level_2.lookup(3, 3)
      destination = level_2.lookup(1, 2)
      expect(level_2.get_path(start, destination).map { |c| coordinates c }).to eq [[3, 3], [2, 3], [1, 2]]
    end
  end

  describe '#do_fov' do
    before do
      @creature = Roguelike::Creature.new x: 2, y: 3, light_radius: 10
      feature = feature_from_map [
        '###########',
        '#.........#',
        '#.........#',
        '#.......#.#',
        '#.........#',
        '###########'
      ]
      @level = Roguelike::Level.new
      @level.set_cells feature
    end
    it "should clear the creature's fov" do
      cell = Roguelike::Cell.new 1000, 2000
      @creature.fov = [cell]
      @level.do_fov @creature
      expect(@creature.fov).not_to include(cell)
    end
    it "should fill the creature's fov" do
      @level.do_fov @creature
      expect(@creature.fov).not_to be_empty
    end
    it "should light the creature's location" do
      @level.do_fov @creature
      expect(@creature.fov.map { |c| c.coordinates.to_a }).to include([2, 3])
    end
    it 'should light the cell that blocks the vision' do
      @level.do_fov @creature
      expect(@creature.fov.map { |c| c.coordinates.to_a }).to include([8, 3])
    end
    it 'should light cells that are visible' do
      @level.do_fov @creature
      expect(@creature.fov.map { |c| c.coordinates.to_a }).to include([7, 3])
    end
    it "should not light cells that aren't visible" do
      @level.do_fov @creature
      expect(@creature.fov.map { |c| c.coordinates.to_a }).not_to include([9, 3])
    end
    it "should use the creature's light radius" do
      @creature.light_radius = 5
      @level.do_fov @creature
      expect(@creature.fov.map { |c| c.coordinates.to_a }).not_to include([7, 3])
    end
  end
end
