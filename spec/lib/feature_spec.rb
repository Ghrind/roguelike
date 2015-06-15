require 'spec_helper'

RSpec.describe Roguelike::Feature do
  let(:feature_1) {
    feature_from_map [
      ' # ',
      ' # ',
      '## ',
      '  #'
    ]
  }

  let(:room_1) {
    feature_from_map [
      '######',
      '#    #',
      '#    #',
      '#    #',
      '######'
    ]
  }

  let(:room_2) {
    feature_from_map [
      '###',
      '#.#',
      '###'
    ]
  }

  let(:room_3) {
    feature_from_map [
      '###',
      '#.#',
      '# #'
    ]
  }

  let(:room_4) {
    feature_from_map [
      '#######',
      '#.....#',
      '##...##',
      ' ##.## ',
      '  ###  '
    ]
  }

  let(:room_5) {
    feature_from_map [
      '#######',
      '#..#..#',
      '#.....#',
      '##...##',
      ' ##### '
    ]
  }

  let(:corridor_1) {
    Roguelike::Corridor.new.build 6, 3
  }

  describe '#mergeable' do
    context 'when all the cells are free' do
      it 'should return true' do
        feature_1 = feature_from_map ['']
        feature_2 = feature_from_map ['#']

        expect(feature_1.mergeable?(feature_2, 0, 0, 0, 0)).to eq true
      end
    end
    context  'when one of the cells is a wall' do
      it 'should return true' do
        feature_1 = feature_from_map ['#']
        feature_2 = feature_from_map ['#']

        expect(feature_1.mergeable?(feature_2, 0, 0, 0, 0)).to eq true
      end
    end
    context 'when one of the cells is not a wall' do
      it 'should return false' do
        feature_1 = feature_from_map ['.']
        feature_2 = feature_from_map ['#']

        expect(feature_1.mergeable?(feature_2, 0, 0, 0, 0)).to eq false
      end
    end
  end

  describe '#to_map' do
    it 'should display the cells in the right direction' do
      feature = Roguelike::Feature.new
      feature.add_cell Roguelike::Cell.new x: 0, y: 0
      feature.add_cell Roguelike::Cell.new x: 0, y: 1

      expect(feature.to_map).to eq ['?', '?']
    end

    it 'should not mind having cells with negative coordinates' do
      feature = Roguelike::Feature.new
      feature.add_cell Roguelike::Cell.new x: -1, y: -2

      expect(feature.to_map).to eq ['?']
    end

    it 'should return an array of strings' do
      expected_map = [
        ' # ',
        ' # ',
        '## ',
        '  #'
      ]

      expect(feature_1.to_map).to eq expected_map
    end
  end

  describe '#map_symbol' do
    context 'when there is no cell' do
      it 'should return a blank space' do
        feature = Roguelike::Feature.new
        expect(feature.map_symbol(nil)).to eq ' '
      end
    end
  end

  describe '#rotate' do
    it 'should return self' do
      expect(feature_1.rotate(:south)).to eq feature_1
    end
    context 'when the desired gravity equals the current gravity' do
      it 'should do nothing' do
        expected_map = feature_1.to_map
        expect(feature_1.rotate(:north).to_map).to eq expected_map
      end
    end
    context 'from north to south' do
      it 'should rotate cells properly' do
        room_3.rotate :south

        expected_map = [
          '# #',
          '#.#',
          '###'
        ]

        expect(room_3.to_map).to eq expected_map
      end
    end
    context 'from north to west' do
      it 'should rotate cells properly' do
        room_3.rotate :west

        expected_map = [
          '###',
          '#. ',
          '###'
        ]

        expect(room_3.to_map).to eq expected_map
      end
    end
    context 'from north to east' do
      it 'should rotate cells properly' do
        room_3.rotate :east

        expected_map = [
          '###',
          ' .#',
          '###'
        ]

        expect(room_3.to_map).to eq expected_map
      end
    end
  end

  describe '#min_x' do
    it 'should find minimum x coordinate' do
      feature = Roguelike::Feature.new
      feature.add_cell Roguelike::Cell.new x: 0, y: 0
      feature.add_cell Roguelike::Cell.new x: 10, y: 0
      feature.add_cell Roguelike::Cell.new x: -7, y: 0

      expect(feature.min_x).to eq -7
    end
  end

  describe '#min_y' do
    it 'should find minimum y coordinate' do
      feature = Roguelike::Feature.new
      feature.add_cell Roguelike::Cell.new x: 0, y: 0
      feature.add_cell Roguelike::Cell.new x: 0, y: 10
      feature.add_cell Roguelike::Cell.new x: 0, y: -7

      expect(feature.min_y).to eq -7
    end
  end

  describe '#max_x' do
    it 'should find maximum x coordinate' do
      feature = Roguelike::Feature.new
      feature.add_cell Roguelike::Cell.new x: 0, y: 0
      feature.add_cell Roguelike::Cell.new x: 10, y: 0
      feature.add_cell Roguelike::Cell.new x: -7, y: 0

      expect(feature.max_x).to eq 10
    end
  end

  describe '#max_y' do
    it 'should find maximum y coordinate' do
      feature = Roguelike::Feature.new
      feature.add_cell Roguelike::Cell.new x: 0, y: 0
      feature.add_cell Roguelike::Cell.new x: 0, y: 10
      feature.add_cell Roguelike::Cell.new x: 0, y: -7

      expect(feature.max_y).to eq 10
    end
  end

  describe '#merge' do
    it 'should merge features together at given location' do
      expected_map = [
        '######     ',
        '#    ######',
        '#    #....#',
        '#    ######',
        '######     '
      ]

      expect(room_1.merge(corridor_1, 5, 2, 0, 1).to_map).to eq expected_map
    end

    context 'with the junction option' do
      it 'should replace junction cell by given cell' do
        expect(room_1.merge(corridor_1, 5, 2, 0, 1, junction: :floor).lookup(5, 2).symbol).to eq '.'
      end
    end
  end

  describe '#lookup' do
    it 'should return cell at location' do
      feature = Roguelike::Feature.new
      cell = Roguelike::Cell.new x: 7, y: 4
      feature.instance_variable_set :@grid, { 4 => { 7 => cell } }

      expect(feature.lookup(7, 4)).to eq cell
    end
  end

  describe '#add_cell' do
    it 'should put cell in the grid' do
      feature = Roguelike::Feature.new
      cell = Roguelike::Cell.new x: 7, y: 4
      feature.add_cell cell

      expect(feature.lookup(7, 4)).to eq cell
    end
    it 'should add cell in the cells collection' do
      feature = Roguelike::Feature.new
      cell = Roguelike::Cell.new x: 7, y: 4
      feature.add_cell cell

      expect(feature.cells).to eq [cell]
    end
    context 'when replacing a cell' do
      it 'should not leave the previous cell' do
        feature = Roguelike::Feature.new
        cell_1 = Roguelike::Cell.new x: 7, y: 4
        cell_2 = Roguelike::Cell.new x: 7, y: 4
        feature.add_cell cell_1
        feature.add_cell cell_2

        expect(feature.cells).to eq [cell_2]
      end
    end
    context 'when coordinates are specified' do
      it 'should change cell coordinates' do
        feature = Roguelike::Feature.new
        cell = Roguelike::Cell.new x: 7, y: 4
        feature.add_cell cell, 5, 10

        expect(cell.x).to eq 5
        expect(cell.y).to eq 10
      end
      it 'should put it at the right place on the grid' do
        feature = Roguelike::Feature.new
        cell = Roguelike::Cell.new x: 7, y: 4
        feature.add_cell cell, 5, 10

        expect(feature.lookup(5, 10)).to eq cell
      end
    end
  end

  describe '#available_junctions' do
    it 'should find the right number of junctions' do
      expect(room_2.available_junctions.size).to eq 4
    end
    it 'should find the right junctions' do
      cells = room_2.available_junctions
      feature = Roguelike::Feature.new
      cells.each { |c| feature.add_cell c }

      expected_map = [
        ' # ',
        '# #',
        ' # '
      ]

      expect(feature.to_map).to eq expected_map
    end
    it 'should set the right direction of the junctions' do
      cells = room_2.available_junctions
      feature = Roguelike::Feature.new
      cells.each { |c| feature.add_cell c }

      expect(feature.lookup(1, 0).direction).to eq :north
      expect(feature.lookup(1, 2).direction).to eq :south
      expect(feature.lookup(2, 1).direction).to eq :east
      expect(feature.lookup(0, 1).direction).to eq :west
    end
  end

  context 'when compositing' do
    it 'should compose the right feature' do
      j1 = room_4.available_junctions.find { |j| j.direction == :west }
      j2 = room_5.available_junctions.find { |j| j.direction == :south }
      room_5.rotate j1.direction
      room_4.merge room_5, j1.x, j1.y, j2.x, j2.y, junction: :floor

      expected_map = [
        '####       ',
        '#..##      ',
        '#...#      ',
        '##..#######',
        '#.........#',
        '#..###...##',
        '#### ##.## ',
        '      ###  '
      ]

      expect(room_4.to_map).to eq expected_map
    end
  end
end

RSpec.describe Roguelike::SquareRoom do
  describe '#build' do
    it 'should build a square room' do
      feature = Roguelike::SquareRoom.new
      expected_map = [
        '####',
        '#..#',
        '#..#',
        '#..#',
        '####'

      ]
      expect(feature.build(4,5).to_map).to eq expected_map
    end
  end
end

RSpec.describe Roguelike::Corridor do
  let(:corridor_1) {
    Roguelike::Corridor.new.build 3, 6
  }

  describe '#available_junctions' do
    context 'when force_gravity is :north' do
      it 'should find the right junctions' do
        cells = corridor_1.available_junctions(:north)

        coordinates = cells.map { |c| [c.x, c.y] }
        expect(coordinates.size).to eq 3
        expect(coordinates).to include [1, 0]
        expect(coordinates).to include [0, 1]
        expect(coordinates).to include [2, 1]
      end
    end

    context 'when force_gravity is :south' do
      it 'should find the right junctions' do
        cells = corridor_1.available_junctions(:south)

        coordinates = cells.map { |c| [c.x, c.y] }
        expect(coordinates.size).to eq 3
        expect(coordinates).to include [1, 5]
        expect(coordinates).to include [0, 4]
        expect(coordinates).to include [2, 4]
      end
    end
  end
end
