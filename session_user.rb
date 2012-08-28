require 'rubygems'
require 'pg'

class SessionUser
  attr_accessor :method_to_invoke, :logger
  
  def initialize(app, opts = { })
    @app = app
    @conn = opts[:conn]
    @method_to_invoke = opts[:method] || :get_user_id
    @logger = opts[:logger]
  end
  
  def call(env)
    send(@method_to_invoke, env)
  end

  private

  # create the DB connection
  def conn
    unless @conn
      # open the database config file
      db_config = YAML.load(ERB.new(File.read("config/ourstage_database.yml")).result )
      database = db_config['development']['database']
      @conn = PG::connect(:dbname => database)
    end
    @conn
  end

  
  def set_user_id(env)
     @req = Rack::Request.new(env)
     user_id = @req.params['user_id']
     if user_id
       env['rack.session']['_ourstage_session'] = {'user_id' =>  user_id} 
       [200, {"Content-Type" => "text/plain"},["Set the Session User ID to #{user_id}"]]
     else
       [200, {"Content-Type" => "text/plain"},["No Session User ID!!!"]]
     end
   end
  
  def get_user_id(env)
    # Call downstream app if our session is missing
    return @app.call(env) unless env['rack.session'] && env['rack.session']['_ourstage_session']
    
    logger.debug "SessionUser#get_user_id: env['rack.session'] = #{env['rack.session']}"
    logger.debug "SessionUser#get_user_id: env['rack.session']['_ourstage_session'] = #{env['rack.session']['_ourstage_session']}"

    # get the user_id from the session
    if user_id = env['rack.session']['_ourstage_session']['user_id']

      # Look up the user in the DB
      query = "select * from users where id = #{user_id}"
      logger.debug "SessionUser#get_user_id: Get user from DB: query = #{query}"
      result_set = conn.exec(query)

      # Add a hash of this user's attributes into the environment so
      # downstream Rack apps can have it!
      if result_set
        env['rack.session.user'] = Array(result_set).first
        logger.debug "SessionUser#get_user_id: env['rack.session.user'] = #{env['rack.session.user'].inspect}"
      end
    end

    # Call the downstream Rack Apps
    status, headers, content = @app.call(env)

    # remove the User from the session hash, don't want it written to cookie!!
    env['rack.session.user'] = nil
    
    [status, headers, content]
  end
end
