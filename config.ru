require 'rubygems'
require 'logger'
require 'rack/async'
%w{ em_async_app tracker_heartbeat session_user promo_judge}.each do |filename|
  require "./#{filename}"
end

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
log = Logger.new("log/#{environment}.log", File::WRONLY | File::APPEND)
case environment
when 'development'
  log.level = Logger::DEBUG
when 'test'
  log.level = Logger::DEBUG
when 'production'
  log.level = Logger::INFO
else
  raise ArgumentError.new("Invalid environment #{environment}, must be #{valid_environments.join(' OR ')}") 
end
use Rack::CommonLogger, log

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
  run EMAsyncApp.new(:method => 'rack_async', :logger => log)
end

# Non-blocking Rack endpoint that returns immediately.
# Runs a SQL query asynchronously.
map "/db_async" do
  # ab -n 100 -c 50 http://127.0.0.1:8111/db_async
  # Requests per second:    4955.40 [#/sec] (mean)
  run EMAsyncApp.new(:method => 'db_async', :query => 'select count(*) from categories', :logger => log)
end

# Health Check Rack endpoint, doesn't get much simpler that this.
map "/health_check" do
  run lambda{ |env| [200, {"Content-Type"=> "text/plain"}, ["Good to go!"]] }
end

use Rack::Session::Cookie,
:key => '_ourstage_session',
:domain => '',
:path => '/',
:expire_after => 2592000,
# Ourstage::Application.config.secret_token = 'ec6811409dab0eaa97f678b8e5c189a60fe21691d23b9aad14667595a3d3856fa59d54b8a081e9093c55e523eb790dbbb11f066739864b9398359238ddb6763c' 
:secret => 'ec6811409dab0eaa97f678b8e5c189a60fe21691d23b9aad14667595a3d3856fa59d54b8a081e9093c55e523eb790dbbb11f066739864b9398359238ddb6763c' 


# pass the environment to the DB connection singleton
OurStage::Rack::DBConn.environment = environment

# Heart Beat Rack endpoint
# insert into the stats DB, heartbeats table
map "/tracker/heartbeat/" do
  # ab -n 100 -c 50 -p test/tracker_heartbeat_data -T 'application/x-www-form-urlencoded' http://127.0.0.1:8111/tracker/heartbeat 
  # Requests per second:    1987.83 [#/sec] (mean)
  run OurStage::Rack::TrackerHeartbeat.new(:logger => log)
end

# Promo Judge Click Rack endpoint
# insert into the ourstage DB, promo_data_judge_clicks table
map "/api/promo_judge/click" do
  # ab -n 100 -c 50 -C promo_code='noisepop' -p test/promo_click_data -T 'application/x-www-form-urlencoded' -H "X-Requested-With: XMLHttpRequest" http://127.0.0.1:8111/api/promo_judge/click
  # Requests per second:    397.84 [#/sec] (mean)
  run PromoJudge.new(:method => :click, :logger => log, :environment => environment)
end
  
use SessionUser, :logger => log

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
   run SessionUser.new(@app,:method => :set_user_id, :logger => log)
end
  
# start this rack app with thin on port 8111
#  thin --rackup config.ru start -p 8111

# same as above but logging request/response (much slower!)
# thin --rackup config.ru start -p 8111 -V


