require 'rubygems'
require 'rack/async'
require 'eventmachine'
require_relative 'logger'
require_relative 'db_connection'
require_relative 'onliner'


# start up on port 8111
# thin --rackup config.ru start -p 8111

# Memcache/Dalli Sessions
# ab -n 1 -c 1 -p test/tracker_heartbeat_data -T 'application/x-www-form-urlencoded' -C '_os_session=dcc1c0058bd31754ff328bb3317b326b' http://127.0.0.1:8111/tracker/heartbeat

# Cookie Sessions ONLY
# test 100 HTTP POST requests by 50 users
# -n number of requests
# -c number of concurrent users/connections
# -p data to POST "activity=dummy_activity&beat=42"
# -T Accept HTTP Header
# -C Cookie data, data is was captured from a session with the main app.
# ab -n 1 -c 1 -p test/tracker_heartbeat_data -T 'application/x-www-form-urlencoded' -C "_ourstage_session=BAh7DEkiD3Nlc3Npb25faWQGOgZFRkkiJTRjZDFlYjg0ZDFlY2JmNmU2OTJhYjU4YTZhYTJlNjRjBjsAVEkiFWN1cnJlbnRfcHJvdG9jb2wGOwBGSSIJaHR0cAY7AEZJIhBfY3NyZl90b2tlbgY7AEZJIjFDUkl5K3hnY2Y1TVYxZko5VTdqRzNYREhQeGdlUnZzQ2QwZHdGaG9iYXNNPQY7AEZJIhZyZWdpc3Rlcl9hc192ZW51ZQY7AEZGSSIccmVnaXN0ZXJfYXNfY29udHJpYnV0b3IGOwBGRkkiDHVzZXJfaWQGOwBGaQNPfktJIg9sYXN0X3Zpc2l0BjsARlU6CURhdGVbC2kAaQNqeiVpAGkAaQBmDDIyOTkxNjE%3D--a6b6fa6c494ff246d3638bf27280b67f4c3fb929" http://127.0.0.1:8111/tracker/heartbeat 

# ab -n 1 -c 1 -p test/tracker_heartbeat_data -T# 'application/x-www-form-urlencoded' -C "_os_session=f378cc859e6209c5467f6e54be75c474" http://127.0.0.1:8111/tracker/heartbeat 

# Send a request with curl
# -d request data
# -b cookies (_ourstage_session cookie value was pulled from a request to the main app)
# curl -v -i -d "activity=dummy_activity&beat=44" "http://127.0.0.1:8111/tracker/heartbeat" -b "_ourstage_session=BAh7DEkiD3Nlc3Npb25faWQGOgZFRkkiJTRjZDFlYjg0ZDFlY2JmNmU2OTJhYjU4YTZhYTJlNjRjBjsAVEkiFWN1cnJlbnRfcHJvdG9jb2wGOwBGSSIJaHR0cAY7AEZJIhBfY3NyZl90b2tlbgY7AEZJIjFDUkl5K3hnY2Y1TVYxZko5VTdqRzNYREhQeGdlUnZzQ2QwZHdGaG9iYXNNPQY7AEZJIhZyZWdpc3Rlcl9hc192ZW51ZQY7AEZGSSIccmVnaXN0ZXJfYXNfY29udHJpYnV0b3IGOwBGRkkiDHVzZXJfaWQGOwBGaQNPfktJIg9sYXN0X3Zpc2l0BjsARlU6CURhdGVbC2kAaQNqeiVpAGkAaQBmDDIyOTkxNjE%3D--a6b6fa6c494ff246d3638bf27280b67f4c3fb929; someother_cookie=bar"
module OurStage
  module Rack
    class TrackerHeartbeat
      attr_accessor :query

      def initialize(opts ={ })
      end

      def call(env)
        # puts "Thread.current = #{Thread.current}"
        # puts "My Object ID = #{self.object_id.inspect}"        
        event_machine do
          begin
            
            req = ::Rack::Request.new(env)

            # debugger
            # xxx = req.session[:user_id]
            
            logger.debug "TrackerHeartbeat#call: request params = #{req.params}"

            session_id = req.session['session_id'] || req.cookies['_os_session']
            user_id = req.session['user_id'] ? req.session['user_id'] : nil;
            activity = req.params['activity']
            remote_ip = req.ip
            beats = req.params['beat']
            referrer = req.referrer || ""
            logger.debug "TrackerHeartbeat::call: session_id:#{session_id}, user_id:#{user_id}, activity:#{activity}, remote_ip:#{remote_ip}, beats:#{beats}, referrer:#{referrer}"
            # session will look empty until we explicity ask for an entry,
            # that's when it's lazily loaded.
            logger.debug "TrackerHeartbeat::call: request.session = #{req.session}"
            
            fail ArgumentError.new("TrackerHeartbeat::call: must have a user id") if !user_id 
            
            # add the site visit to the ourstage DB iff this is the first
            # visit of the day for a user.
            # today = Time.parse("2012-08-30 12:19:31 EDT" ).utc.to_date
            today = Time.now.utc.to_date
            if req.session['last_visit'] && req.session['last_visit'].to_date != today
              add_site_visit(user_id, today) if user_id
              req.session['last_visit'] = today
            end

            # get the user's level
            get_user_level(user_id) do |user_level|
              # track onliners in the ourstage DB
              onliner = OurStage::Rack::Onliner.new(:user_id => user_id, :user_level => user_level, :activity => activity,
                          :channel => req.params['channel'], :target_user => req.params['target_user'],
                                          :ip_addr => remote_ip, :updated_at => Time.now.utc)
              logger.debug "TrackerHeartbeat::call: onliner = #{onliner.inspect}"
              Onliner.process(onliner)
            end
            
            # add the heartbeat to the stats DB
            add_stats_heartbeat( user_id, session_id, activity, remote_ip, referrer, beats)
            
          rescue  Exception => e
            logger.error "TrackerHeartbeat::call Exception => #{e.inspect}"
            
          end
        end

        # signal to the web server, Thin, that it's HTTP request will be
        # handled asynchronously. It will not block waiting for response.
        env['async.callback'].call([200, {}, ["Tracker Heartbeat!!!!!!!"]])
        logger.debug "TrackerHeartbeat::call returning"
        # returning this signals to the server we are sending an async
        # response
        ::Rack::Async::RESPONSE
        
      end

      private

      def logger
        @log ||= OurStage::Rack::Logger.logger
      end
      
      # TODO: batch up DB calls to get user levels
      def get_user_level(user_id, &blk)
        logger.debug "TrackerHeartbeat::get_user_level: for user #{user_id}"
        
        sql = %Q<SELECT user_level FROM users WHERE id = #{user_id}>
          logger.debug "TrackerHeartbeat::get_user_level: SQL = #{sql.inspect}"
        df = ourstage_dbconn.execute(sql)

        df.callback do |results|
          user_level = Array(results).first["user_level"]
          logger.debug "TrackerHeartbeat::get_user_level: success,  user_level = #{user_level}"
          blk.call(user_level) if block_given?
        end

        # error callback
        df.errback do |ex|
          if ex.is_a?(PG::Result)
            logger.error "TrackerHeartbeat::get_user_level: Exception, error_message = #{ex.error_message}"
          else
            logger.error "TrackerHeartbeat::get_user_level: Exception = #{ex.inspect}"
          end
          raise ex
        end
      end
      
      # add the heartbeat to the stats DB
      def add_stats_heartbeat( user_id, session_id, activity, ip_addr, referrer, beat)
        created_at = Time.now
        # Let the DB generate errors!
        # fail ArgumentError.new("TrackerHeartbeat::add_stats_heartbeat: must have a user id") if !user_id
        # fail ArgumentError.new("TrackerHeartbeat::add_stats_heartbeat: must have a session id") if !session_id                 
        # fail ArgumentError.new("TrackerHeartbeat::add_stats_heartbeat: must have an activity") if !activity
        # fail ArgumentError.new("TrackerHeartbeat::add_stats_heartbeat: must have an activity") if !ip_addr

        # insert into the stats DB heartbeats table
        sql = <<-SQL.gsub(/\s{2}/, '')
          INSERT INTO heartbeats (session_id, user_id, activity, ip_addr,
          referrer, created_at, beat) VALUES ('#{session_id}', '#{user_id}',
          '#{activity}', '#{ip_addr}', '#{referrer}', '#{created_at}', '#{beat}')

        SQL
        logger.debug "TrackerHeartbeat::add_stats_heartbeat: SQL = #{sql.inspect}"

        # Make the non-blocking/async query, returns a EM::Deferrable
        df = stats_dbconn.execute(sql)

        # success callback
        df.callback { |result|
          logger.debug "TrackerHeartbeat::add_stats_heartbeat: success"
        }

        # error callback
        df.errback do |ex|
          if ex.is_a?(PG::Result)
            logger.error "TrackerHeartbeat::add_stats_heartbeat: Exception, error_message = #{ex.error_message}"
          else
            logger.error "TrackerHeartbeat::add_stats_heartbeat: Exception = #{ex.inspect}"
          end
          raise ex
        end
      end

      # add the site visit to the ourstage DB
      def add_site_visit(user_id, created_at)
        
        sql = %Q<INSERT INTO site_visits (user_id, created_at) VALUES ('#{user_id}', '#{created_at}');>
          logger.debug "TrackerHeartbeat::add_site_visit: SQL = #{sql}"
        df = ourstage_dbconn.execute(sql)

        # success callback
        df.callback do |result|
          logger.debug "TrackerHeartbeat::add_site_visit: success adding visit for user #{user_id} on #{created_at}"
        end

        # error callback
        df.errback do |ex|
          if ex.is_a?(PG::Result) && ex.error_field( PG::Result::PG_DIAG_SQLSTATE ) == "23505"
            # ex.error_message =~ /duplicate key value violates unique constraint \"uniq_user_visits\"/
            # This error, constraint violation, is OK. It will not
            # allow adding 2 site visits on the same day for the same
            # user. Note, this logs in INFO level, it's not an error.
            logger.info "TrackerHeartbeat::add_site_visit: Exception, DB results = #{ex.inspect}"
            logger.info "TrackerHeartbeat::add_site_visit: Exception, DB results = #{Array(ex).inspect}"
            logger.info "TrackerHeartbeat::add_site_visit: Exception, postgres message = #{ex.error_message}"
          elsif ex.is_a?(PG::Result)
            logger.error "TrackerHeartbeat::add_site_visit: Exception, DB results = #{Array(ex).inspect}"
            logger.error "TrackerHeartbeat::add_site_visit: Exception, error_message = #{ex.error_message}"
            raise ex
          else
            logger.error "TrackerHeartbeat::add_site_visit: Exception = #{ex.inspect}"        
            raise ex
          end
        end
      end

      # get the non-blocking Postgres connection for the ourstage DB
      def ourstage_dbconn
        OurStage::Rack::DBConn.ourstage_dbconn
      end

      # get the non-blocking Postgres connection for the stats DB
      def stats_dbconn
        OurStage::Rack::DBConn.stats_dbconn
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

    end #class TrackerHeartbeat
  end # module Rack
end # module OurStage
