require 'rubygems'
require 'eventmachine'


# start up on port 8111
# thin --rackup config.ru start -p 8111

# Memcache/Dalli Sessions
# ab -n 1 -c 1 -C '_os_session=dcc1c0058bd31754ff328bb3317b326b' http://127.0.0.1:8111/dalli_session

module OurStage
  module Rack
    class DalliSession

      def initialize(opts ={ })
      end

      def call(env)
        # puts "Thread.current = #{Thread.current}"
        # puts "My Object ID = #{self.object_id.inspect}"        
        event_machine do
          begin
            
            req = ::Rack::Request.new(env)
            session_id = req.session['session_id'] || req.cookies['_os_session']
            user_id = req.session['user_id'] ? req.session['user_id'] : nil;

            # session will look empty until we explicity ask for an entry,
            # that's when it's lazily loaded.
            puts "DalliSession::call: request.session = #{req.session}"
            
          rescue  Exception => e
            puts "Dalli::call Exception => #{e.inspect}"
          end
        end

        # signal to the web server, Thin, that it's HTTP request will be
        # handled asynchronously. It will not block waiting for response.
        env['async.callback'].call([200, {}, ["Dalli Session"]])
        logger.info "DalliSession::call returning"
        # returning this signals to the server we are sending an async
        # response
        ::Rack::Async::RESPONSE
        
      end

      # make sure EventMachine is running (if we're on thin it'll be up
      # and running, but this isn't the case on other servers).
      def event_machine(&block)
        if EM.reactor_running?
          # logger.debug "Reactor is running!"
          block.call
        else
          # logger.debug "Reactor is NOT running!"
          Thread.new {EM.run}
          EM.next_tick(block)
        end
      end

    end
  end # module Rack
end # module OurStage
