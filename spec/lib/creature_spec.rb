require 'spec_helper'

RSpec.describe Roguelike::Creature do
  describe '#step_in' do
    before do
      @cell = Roguelike::Cell.new x: 1, y: 5
      @creature = Roguelike::Creature.new
    end
    it 'should call cell.on_step_in with self' do
      expect(@cell).to receive(:on_step_in).with(@creature)
      @creature.step_in @cell
    end
    it 'should change creature coordinates for cell coordinates' do
      @creature.step_in @cell
      expect(@creature.x).to eq @cell.x
      expect(@creature.y).to eq @cell.y
    end
    it 'should visit cell' do
      expect(@creature).to receive(:visit).with(@cell)
      @creature.step_in @cell
    end
  end
  describe '#in_sight?' do
    before do
      @cell = Roguelike::Cell.new
      @creature = Roguelike::Creature.new
    end
    context "when the cell is in the creature's fov" do
      it 'should return true' do
        @creature.fov = [@cell]
        expect(@creature.in_sight?(@cell)).to eq true
      end
    end
    context "when the cell is not in the creature's fov" do
      it 'should return false' do
        expect(@creature.in_sight?(@cell)).to eq false
      end
    end
  end
  describe '#step_out' do
    before do
      @cell = Roguelike::Cell.new
      @creature = Roguelike::Creature.new
      @creature.step_in @cell
    end
    it 'should call cell.on_step_out with self' do
      expect(@cell).to receive(:on_step_out).with(@creature)
      @creature.step_out @cell
    end
    it 'should reset coordinates' do
      @creature.step_out @cell
      expect(@creature.x).to be_nil
      expect(@creature.y).to be_nil
    end
  end
end
