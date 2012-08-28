class SessionTest
  attr_accessor :method, :logger, :session_stuff
  
  def initialize(options = { })
    @method_to_invoke = options[:method]
    @logger = options[:logger]
    @session_stuff = options[:session_stuff]
  end
  def call(env)
    send(@method_to_invoke, env)
  end
  private

  def set(env)
    session = env['rack.session']
    # add a count to the session, increments on every request
    session[:count] = session[:count] ? session[:count] +1 : 0;

    session.merge!(session_stuff)
    [200, {"Content-Type" => "text/plain"}, ["Set session to #{session.to_hash.inspect}"]]
  end
  
  def show(env)
    req = Rack::Request.new(env)
    # logger.debug "ShowSession#call: req.session.to_hash = #{req.session.to_hash}"
    # logger.debug "ShowSession#call: req.session.class.name = #{req.session.class.name.inspect}"
    # logger.debug "ShowSession#call: req.session_options = #{req.session_options.inspect}"

    content = "Session = #{req.session.to_hash.inspect}"
    content << "Session Options = #{req.session_options}"

    session = env['rack.session']
    session_options = env['rack.session.options']

    logger.debug "ShowSession#call: session from env['rack.session'] = #{session.inspect}"
    logger.debug "ShowSession#call: session from env['rack.session.options'] = #{session_options.inspect}"
    
    [200, {"Content-Type" => "text/plain"}, [content]]
  end

end
