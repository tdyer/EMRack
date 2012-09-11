#!/usr/bin/env ruby
# NEEDS activerecord < 2.3.8 because
# ActiveRecord::Base.allow_concurrency is deprecated in later version
# of AR,
# All should be in the Gemfile in this directory, just "bundle install"
# OR
# gem install activerecord --version='2.3.8'

%w(rubygems rack activerecord yaml erb).each {  |dep| require dep } 

# yep the port we're listening on
PORT=3131

# Hook up to the Decision Support development  DB. 
db_config = YAML.load( ERB.new(File.read("ourstage_database.yml")).result )
AR = ActiveRecord::Base 
AR.allow_concurrency = true
AR.establish_connection(db_config['development'])

class User < ActiveRecord::Base
end

class DSViewer

  # method to dispatch to
  attr_accessor :method_to_invoke

  # options -  will have the method to invoke :method => <method_name>
  # NOTE: could built a real router, just not into it now...
  def initialize(options={})
    @method_to_invoke = options[:method] || "no_method_here"
  end

  # handle dispatch problems
  def method_missing(method)
    # show the path that we're trying to dispatch to
    method  = @req.path_info.split('/')[1]

    puts "WTF: there ain't no stinking method named #{method} DUDE"
    "\nWTF: there ain't no stinking method named #{method} DUDE\n" 
  end


  # This will choose the format, (xml, json, yaml, ...) based on 
  # URI suffix (.xml, .json, ...)
  # ex: http://localhost:3131/user/311.xml will reply wih XML format user object

  # ar - ActiveRecord model where rendering

  # TODO: Look at HTTP  headers to determine the format
  # BUG: Only works for records using the found by id, ex: /user/1.xml 
  # not /user/tdyer.xml
  def output_format(ar)
    # get the url suffix (.xml, .json,...)
    @format = @req.path_info.split('.').last

    # see if it's xml, json, yaml
    f = %w{ xml json yaml}.find{  |f| f ==@format }

    # convert to the method to_xml, to_json,...
    ar_method = f ? "to_#{f}": "attributes" 

    # xml => ar.to_xml, json => ar.to_json else ar.inspect
    ar.send(ar_method.to_sym)
  end

  # Invoked by Rack, env is the HTTP request headers hash
  # contructed by Rack and the Web Server (mongrel, thin,...)
  def call(env)
    @req = Rack::Request.new(env)
    content = send(@method_to_invoke.to_sym) 
    @res = Rack::Response.new( [content])
    @res.finish
  end

  def root
    "<html><body>Root of the side, </body></html>"
  end

  def first_user
    User.first.to_xml
  end


  # Find the user and reply with the correct format representation
  # (xml, json,...)
  def user
    # handles /user/{id} or /user/{login_name}
    second_param = @req.path_info.split('/')[1]
    id = second_param.to_i
    user = (id != 0 ? User.find(id) : User.find_by_user_name(second_param))
    output_format(user)
  end

  # raises and exception
  def boom
    raise "boom baby boom"
  end
end

# The HTTP Request filters thru all of these before
# being routed to the corrent DSViewer method

app = Rack::Builder.new {  
  use Rack::CommonLogger 
  use Rack::ShowExceptions 
  map "/" do  # dispatch/route for the root
    use Rack::Lint 
    run DSViewer.new(:method => 'root')
  end 
  map "/boom" do |m| # dispatch/route for /boom
    # just raises and exception
    run DSViewer.new(:method => 'boom')
  end 
  map "/user" do |m| # dispatch/route for /users
    # finds a user by id or login_name
    run DSViewer.new(:method => 'user')
  end 

}    

# invoked the daemo
# rackup simple_active_record_3.rbn
#Rack::Handler::Mongrel.run app, :Port => 3131
Rack::Handler::Thin.run app, :Port => 3131
# Rack::Handler::WEBrick.run app, :Port => 3131
# To test:
# curl http://localhost:3131  -v
# curl http://localhost:3131/user/tdyer  -v
# curl http://localhost:3131/user/311  -v
# curl http://localhost:3131/user/311.json  -v
# curl http://localhost:3131/user/1.xml  -v

