require 'websocket-eventmachine-client'
require 'thin'

module WebsocketHelper
  # FIXME Use a test logger
  Thin::Logging.silent = true

  def websocket_send(app, message)
    result = nil

    thread_1 = Thread.new do
      Faye::WebSocket.load_adapter('thin')
      thin = Rack::Handler.get('thin')
      thin.run app, Port: 9293
    end

    # FIXME Use pure ruby
    loop do
      break if `curl -sw "%{http_code}" "http://localhost:9293" -o /dev/null` == '200'
    end

    thread_2 = Thread.new do
      EventMachine.run do
        # Mandatory to be threadsafe
        # https://github.com/eventmachine/eventmachine/wiki/FAQ#does-em-work-with-other-ruby-threads-running
        EventMachine.next_tick do
          ws = WebSocket::EventMachine::Client.connect(:uri => 'ws://localhost:9293')

          ws.onopen do
            ws.send message
          end

          ws.onmessage do |msg, type|
            result = msg
            EventMachine.stop
          end

          #ws.onclose do |code, reason|
          #  puts "Disconnected with status code: #{code}"
          #end
        end
      end
    end

    thread_1.join
    thread_2.join
    Thread.kill(thread_1)

    result
  end
end
