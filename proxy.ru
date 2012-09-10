require 'rubygems'
require 'rack'
require 'rack-proxy'

# This will act as Proxy to redirect to the backend main ourstage app
# and the Rack handlers. Using this in development to simulate a
# production HTTP proxy.

if ENV['RACK_ENV'] !~ /(development|dev_verbose)/
  # to test: thin --rackup proxy.ru start -p 8888 -e production
  fail "Proxy only runs in development mode!!!"
end

# Main App URL
# curl http://localhost:8888/

# Tracker Rack Endpoint/URL
# curl http://localhost:8888/tracker/heartbeat

# To start the proxy in development mode on port 8888
# thin --rackup proxy.ru start -p 8888
# To start the proxy in development verbose mode 
# thin --rackup proxy.ru start -p 8888 -e dev_verbose
class AppProxy < Rack::Proxy
  def initialize(app, opts = { })
    @app = app
  end

  def rewrite_env(env)
    show_rack_environment(env) if ENV['RACK_ENV'] == 'dev_verbose'
    
    @req = Rack::Request.new(env)
    puts "request.path = #{@req.path}"
    
    if @req.path !~ %r{^/tracker/heartbeat}
      env["HTTP_HOST"] = 'localhost:3333'
    else
      env["HTTP_HOST"] = 'localhost:8111'
    end
    env
  end

  private

    def show_rack_environment(env)
    puts
    puts '*'*10 << " Environment:" << '*'*10
    env.each do |k, v|
      puts "#{k}: #{v}"
    end
  end

end

use Rack::ShowExceptions
use AppProxy


map "/dev_proxy" do
   run lambda{ |env| [200, {"Content-Type"=> "text/plain"}, ["Development Proxy Route!!!!"]] }
end

