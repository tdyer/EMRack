require 'rubygems'
require 'yaml'
require 'erb'
require 'rack/async'
require 'eventmachine'
require 'em-postgres'

# start up on port 8111
# thin --rackup config.ru start -p 8111

# test 100 HTTP POST requests by 50 users
# ab -n 100 -c 50 -p test/tracker_heartbeat_data -T 'application/x-www-form-urlencoded' http://127.0.0.1:8111/tracker/heartbeat 

# Data to POST is in tracker_heartbeat_post_data:
# session_id=1234&user_id=33&activity=dummy_activity&beat=44

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
        logger.debug "TrackerHeartbeat::call request.session[:id] = #{req.session[:id]}"

        user_id = req.params['user_id'] ? req.params['user_id'] : nil;

        # add the site visit to the ourstage DB
        add_site_visit(req, user_id) if user_id
        
        # TODO: track onliners

        # add the heartbeat to the stats DB
        add_stats_heartbeat(req, user_id)
        
        # signal to the web server, Thin, that it's HTTP request will be
        # handled asynchronously. It will not block
        env['async.callback'].call([200, {}, ["Tracker Heartbeat!!!!!!!"]])
      rescue  Exception => e
        logger.debug "TrackerHeartbeat::call Exception => #{e.inspect}"
      end
      
    end
    # returning this signals to the server we are sending an async
    # response
    Rack::Async::RESPONSE
  end

  private
  
  # add the heartbeat to the stats DB
  def add_stats_heartbeat(req, user_id)
    session_id = req.params['session_id']
    activity = req.params['activity']
    ip_addr = req.ip
    referrer = req.referrer || ""
    created_at = Time.now
    beat = req.params['beat']

    
    # insert into the stats DB heartbeats table
    sql = "INSERT INTO heartbeats (session_id, user_id, activity, ip_addr, referrer, created_at, beat) VALUES (\'#{session_id}\', \'#{user_id}\', \'#{activity}\', \'#{ip_addr}\', \'#{referrer}\', \'#{created_at}\', \'#{beat}\');"
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
        logger.debug "TrackerHeartbeat::add_stats_heartbeat: Exception, error_message = #{ex.error_message}"
      else
        logger.debug "TrackerHeartbeat::add_stats_heartbeat: Exception = #{ex.inspect}"
      end
      raise ex
    end
  end
  
  def add_site_visit(request, user_id)
    # ourstage time
    # TODO: convert to ourstage time
    created_at = Time.now # Time.now.in_time_zone('EST5EDT').beginning_of_day

    sql = "INSERT INTO site_visits (user_id, created_at) VALUES (\'#{user_id}\', \'#{created_at}\');"
    logger.debug "TrackerHeartbeat::add_site_visit: SQL = #{sql}"            
    df = ourstage_dbconn.execute(sql)

    # success callback
    df.callback do |result|
      logger.debug "TrackerHeartbeat::add_site_visit: success"
    end

    # error callback
    df.errback do |ex|
      if ex.is_a?(PG::Result) && ex.error_message =~ /duplicate key value violates unique constraint \"uniq_user_visits\"/
        # This error is OK, will not suceeded at adding 2 site visits
        # on the same day
        logger.debug "TrackerHeartbeat::add_site_visit: Exception, DB results = #{Array(ex).inspect}"
        logger.debug "TrackerHeartbeat::add_site_visit: Exception, error_message = #{ex.error_message}"
      else
        logger.debug "TrackerHeartbeat::add_site_visit: Exception = #{ex.inspect}"        
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
