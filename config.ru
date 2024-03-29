require 'rubygems'
require 'rack/async'
require 'rack/session/dalli'
# require 'ruby-debug'
%w{ logger em_async_app tracker_heartbeat session_user promo_judge dalli_session}.each do |filename|
  require "./#{filename}"
end

# Debugger.start

use Rack::ShowExceptions

# Set the development, test or production environment
# development (the default)
# thin --rackup config.ru start -p 8111
# production
# thin --rackup config.ru start -p 8111 -e production
environment = ENV['RACK_ENV']
valid_environments = %w{development test production}
unless valid_environments.include?(environment)
  raise ArgumentError.new("Invalid environment #{environment}, must be #{valid_environments.join(' OR ')}") 
end

# set up the Apache-like logger
OurStage::Rack::Logger.environment = environment
use Rack::CommonLogger, OurStage::Rack::Logger.logger

# for handling asyn requests
use Rack::Async

# damn dumb Rack endpoint, blocking request
map "/rack" do
  # ab -n 100 -c 50 http://127.0.0.1:8111/rack
  # Requests per second:    3512.10 [#/sec] (mean)
  run EMAsyncApp.new(:method => 'rack_standard')
end

# Non-blocking Rack endpoint that returns immediately.
# It runs a logging statement in a EM timer that simulates
# a really slow blocking call that get's run asynchronously.
map "/rack_async" do
  # ab -n 100 -c 50 http://127.0.0.1:8111/rack_async
  # Requests per second:    5224.39 [#/sec] (mean)
  run EMAsyncApp.new(:method => 'rack_async', :logger => OurStage::Rack::Logger.logger)
end

# Non-blocking Rack endpoint that returns immediately.
# Runs a SQL query asynchronously.
map "/db_async" do
  # ab -n 100 -c 50 http://127.0.0.1:8111/db_async
  # Requests per second:    4955.40 [#/sec] (mean)
  run EMAsyncApp.new(:method => 'db_async', :query => 'select count(*) from categories', :logger => OurStage::Rack::Logger.logger)
end

# Health Check Rack endpoint, doesn't get much simpler that this.
map "/rack_healthcheck" do
  run lambda{ |env| [200, {"Content-Type"=> "text/plain"}, ["Rack Healthcheck, Good to go!"]] }
end

# Session storage is backed by Memcache, NOTE: the :key's value MUST
# match the key in the main app config/initializers/session_store.rb
namespace = (RUBY_VERSION.to_f >= 1.9 ? "#{RUBY_VERSION.to_f}:_session_id" : "_session_id")
use Rack::Session::Dalli, :key => '_os_session', :namespace => namespace

# pass the environment to the DB connection singleton
OurStage::Rack::DBConn.environment = environment

map "/dalli_session/" do
  run OurStage::Rack::DalliSession.new
end

# Heart Beat Rack endpoint
# insert into the stats DB, heartbeats table
map "/tracker/heartbeat/" do
  run OurStage::Rack::TrackerHeartbeat.new
end

# Promo Judge Click Rack endpoint
# insert into the ourstage DB, promo_data_judge_clicks table
map "/api/promo_judge/click" do
  # ab -n 100 -c 50 -C promo_code='noisepop' -p test/promo_click_data -T 'application/x-www-form-urlencoded' -H "X-Requested-With: XMLHttpRequest" http://127.0.0.1:8111/api/promo_judge/click
  # Requests per second:    397.84 [#/sec] (mean)
  run PromoJudge.new(:method => :click, :logger => OurStage::Rack::Logger.logger, :environment => environment)
end
  
use SessionUser, :logger => OurStage::Rack::Logger.logger

# just a dummy make sure that the above SessionUser set the user info
# in env['rack.session.user']
map '/test' do
  run lambda { |env|
    puts "TEST: User info is in env['rack.session.user'] = #{env['rack.session.user']}"
    [200, {"Content-Type"=> "text/plain"}, ["HEY Good to go!"]]
  }
end

# just a dummy app to set the user's id in the session, '_ourstage_session'
# http://localhost:8111/set_user_id?user_id=99
map "/set_user_id" do
   run SessionUser.new(@app,:method => :set_user_id, :logger => OurStage::Rack::Logger.logger)
end
  
# start this rack app with thin on port 8111
#  thin --rackup config.ru start -p 8111

# same as above but logging request/response (much slower!)
# thin --rackup config.ru start -p 8111 -V


