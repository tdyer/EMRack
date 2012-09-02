require 'rubygems'
require 'yaml'
require 'erb'
require 'rack/async'
require 'eventmachine'
require 'em-postgres'

# start up on port 8111
# thin --rackup config.ru start -p 8111

# test 100 HTTP POST requests by 50 users
# -n number of requests
# -c number of concurrent users/connections
# -p data to POST "activity=dummy_activity&beat=42"
# -T Accept HTTP Header
# -C Cookie data, data is was captured from a session with the main app.
# ab -n 1 -c 1 -p test/tracker_heartbeat_data -T 'application/x-www-form-urlencoded' -C "_ourstage_session=BAh7DEkiD3Nlc3Npb25faWQGOgZFRkkiJTRjZDFlYjg0ZDFlY2JmNmU2OTJhYjU4YTZhYTJlNjRjBjsAVEkiFWN1cnJlbnRfcHJvdG9jb2wGOwBGSSIJaHR0cAY7AEZJIhBfY3NyZl90b2tlbgY7AEZJIjFDUkl5K3hnY2Y1TVYxZko5VTdqRzNYREhQeGdlUnZzQ2QwZHdGaG9iYXNNPQY7AEZJIhZyZWdpc3Rlcl9hc192ZW51ZQY7AEZGSSIccmVnaXN0ZXJfYXNfY29udHJpYnV0b3IGOwBGRkkiDHVzZXJfaWQGOwBGaQNPfktJIg9sYXN0X3Zpc2l0BjsARlU6CURhdGVbC2kAaQNqeiVpAGkAaQBmDDIyOTkxNjE%3D--a6b6fa6c494ff246d3638bf27280b67f4c3fb929" http://127.0.0.1:8111/tracker/heartbeat 

# Send a request with curl
# -d request data
# -b cookies (_ourstage_session cookie value was pulled from a request to the main app)
# curl -v -i -d "activity=dummy_activity&beat=44" "http://127.0.0.1:8111/tracker/heartbeat" -b "_ourstage_session=BAh7DEkiD3Nlc3Npb25faWQGOgZFRkkiJTRjZDFlYjg0ZDFlY2JmNmU2OTJhYjU4YTZhYTJlNjRjBjsAVEkiFWN1cnJlbnRfcHJvdG9jb2wGOwBGSSIJaHR0cAY7AEZJIhBfY3NyZl90b2tlbgY7AEZJIjFDUkl5K3hnY2Y1TVYxZko5VTdqRzNYREhQeGdlUnZzQ2QwZHdGaG9iYXNNPQY7AEZJIhZyZWdpc3Rlcl9hc192ZW51ZQY7AEZGSSIccmVnaXN0ZXJfYXNfY29udHJpYnV0b3IGOwBGRkkiDHVzZXJfaWQGOwBGaQNPfktJIg9sYXN0X3Zpc2l0BjsARlU6CURhdGVbC2kAaQNqeiVpAGkAaQBmDDIyOTkxNjE%3D--a6b6fa6c494ff246d3638bf27280b67f4c3fb929; someother_cookie=bar"

class TrackerHeartbeat
  attr_accessor :query, :logger, :environment

  def initialize(opts ={ })
    @logger = opts[:logger]
    @environment = opts[:environment]  
  end
  

  def call(env)
    event_machine do
      begin
        req = Rack::Request.new(env)
        logger.debug "TrackerHeartbeat#call: request params = #{req.params}"
        # logger.debug "TrackerHeartbeat::call: request.cookies = #{req.cookies.inspect}"
        logger.debug "TrackerHeartbeat::call: request.session[:session_id] = #{req.session[:session_id]}"
        logger.debug "TrackerHeartbeat::call: request.session[:user_id] = #{req.session[:user_id]}"
        # session will look empty until to explicity ask for an entry,
        # that's when it's lazily loaded
        logger.debug "TrackerHeartbeat::call: request.session = #{req.session}"

        session_id = req.session['session_id']
        user_id = req.session['user_id'] ? req.session['user_id'] : nil;
        activity = req.params['activity']
        remote_ip = req.ip
        beats = req.params['beat']
        referrer = req.referrer || ""


        # add the site visit to the ourstage DB iff this is the first
        # visit of the day for a user.
        # today = Time.parse("2012-08-30 12:19:31 EDT" ).utc.to_date
        today = Time.now.utc.to_date
        if req.session['last_visit'].to_date != today
          add_site_visit(user_id, today) if user_id
          req.session['last_visit'] = today
        end

        # TODO: track onliners
        
        # add the heartbeat to the stats DB
        add_stats_heartbeat( user_id, session_id, activity, remote_ip, referrer, beats)
        
        # signal to the web server, Thin, that it's HTTP request will be
        # handled asynchronously. It will not block
        env['async.callback'].call([200, {}, ["Tracker Heartbeat!!!!!!!"]])
      rescue  Exception => e
        logger.error "TrackerHeartbeat::call Exception => #{e.inspect}"
      end
      
    end
    logger.debug "TrackerHeartbeat::call returning"
    # returning this signals to the server we are sending an async
    # response
    Rack::Async::RESPONSE
  end

  private
  
  # add the heartbeat to the stats DB
  def add_stats_heartbeat( user_id, session_id, activity, ip_addr, referrer, beat)
    created_at = Time.now
    
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
      if ex.is_a?(PG::Result) && ex.error_message =~ /duplicate key value violates unique constraint \"uniq_user_visits\"/
        # This error, constraint violation, is OK. It will not
        # allow adding 2 site visits on the same day for the same
        # user.
        logger.info "TrackerHeartbeat::add_site_visit: Exception, DB results = #{Array(ex).inspect}"
        logger.info "TrackerHeartbeat::add_site_visit: Exception, error_message = #{ex.error_message}"
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
  # get the non-blocking Postgres connection for the stats DB
  def ourstage_dbconn
    unless @conn
      # open the database config file
      db_config = YAML.load(ERB.new(File.read("config/ourstage_database.yml")).result )
      database = db_config[environment]['database']
      @conn = EventMachine::Postgres.new(:database => database)
      @conn.setnonblocking(true) # may not be needed?     
    end
    @conn
  end

  # get the non-blocking Postgres connection for the stats DB
  def stats_dbconn
    unless @stats_conn
      # open the database config file
      db_config = YAML.load(ERB.new(File.read("config/stats_database.yml")).result )
      database = db_config[environment]['database']
      @stats_conn = EventMachine::Postgres.new(:database => database)
      @stats_conn.setnonblocking(true) # may not be needed?     
    end
    @stats_conn
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
