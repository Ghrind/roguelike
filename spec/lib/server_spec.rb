require 'spec_helper'

describe Roguelike::Server do

  let :server do
    Roguelike::Server.new 'public'
  end

  let :app do
    server.application
  end

  it 'should serve index.html' do
    get '/'
    expect(last_response).to be_ok
    expect(last_response.body).to match /<html>/
    expect(last_response.headers['Content-Type'] ).to eq 'text/html'
  end
  
  it 'should serve /roguelike.proto' do
    get '/roguelike.proto'
    expect(last_response).to be_ok
    expect(last_response.body).to match /package roguelike;/
    expect(last_response.headers['Content-Type'] ).to eq 'application/x-protobuf'
  end

  it 'should serve ByteBufferAB.min.js' do
    get '/ByteBufferAB.min.js'
    expect(last_response).to be_ok
    expect(last_response.body).to match /ByteBufferAB/
    expect(last_response.headers['Content-Type'] ).to eq 'application/javascript'
  end

  it 'should serve ProtoBuf.min.js' do
    get '/ProtoBuf.min.js'
    expect(last_response).to be_ok
    expect(last_response.body).to match /ProtoBuf/
    expect(last_response.headers['Content-Type'] ).to eq 'application/javascript'
  end

  context 'when the path is unknown' do
    it 'should serve a 404 page' do
      get '/foobar'
      expect(last_response.status).to eq 404
      expect(last_response.body).to match /Not found/
      expect(last_response.body).to match /foobar/
      expect(last_response.headers['Content-Type'] ).to eq 'text/plain'
    end
  end

  context 'when receiving message from the websocket' do
    it 'should pass message to #apply_command' do
      expect(server).to receive(:apply_command).with('foobar').and_return({})
      websocket_send(app, 'foobar')
    end
    it 'should return a GameMessage' do
      expect(server).to receive(:apply_command).with('foobar').and_return({cells: [Roguelike::Cell.new(0, 0)]})
      message = Roguelike::GameMessage.new
      message.parse_from_string websocket_send(app, 'foobar')
      expect(message.cells.count).to eq 1
    end

    context 'when receiving game.new' do
      it 'should start a new game' do
        websocket_send(app, 'game.new')
        expect(server.game).not_to be_nil
      end
      it 'should return a GameMessage' do
        expect(server).to receive(:start_new_game)
        message = parse_game_message websocket_send(app, 'game.new')
        expect(message.command).to eq 'game.new'
      end
    end

    context 'when receiving game.current_state' do
      describe 'the GameMessage response' do
        it 'should contain all visited cells'
        it 'should contain player info'
      end
      it 'should parse player FOV'
    end

    context 'when receiving a player command' do
      it 'should tick game with player command'
      describe 'the GameMessage response' do
        it 'should contain return value of Game#tick'
      end
      it 'should parse player FOV'
    end
  end
end
