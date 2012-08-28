require 'rubygems'
require 'rack'
require 'logger'

require_relative 'session_decode'
require_relative 'session_test'

builder_app =  Rack::Builder.new do
  # set up the Apache-like logger
  log = Logger.new("rack_session.log", File::WRONLY | File::APPEND)
  log.level = Logger::DEBUG
  use Rack::CommonLogger, log

  use Rack::ShowExceptions

  # example of how the session is decrypt/decoded
  # use SessionDecode
  
  use Rack::Session::Cookie,
  :key => '_ourstage_session',
  :domain => '',
  :path => '/',
  :expire_after => 2592000,
  # Ourstage::Application.config.secret_token = 'ec6811409dab0eaa97f678b8e5c189a60fe21691d23b9aad14667595a3d3856fa59d54b8a081e9093c55e523eb790dbbb11f066739864b9398359238ddb6763c' 
  :secret => 'ec6811409dab0eaa97f678b8e5c189a60fe21691d23b9aad14667595a3d3856fa59d54b8a081e9093c55e523eb790dbbb11f066739864b9398359238ddb6763c' 

  map '/show_session' do
    run SessionTest.new(:method => :show, :logger => log)
  end

  map '/set_session' do
    run SessionTest.new(:method => :set, :logger => log, :session_stuff => {"some_key" => "some_value" })
  end

end

PORT = 3131
Rack::Handler::Thin.run builder_app, :Port => PORT

# To Run
# ruby rack_session

# Logging
# tail -f rack_session.log

# in a browser
# set the session
# http://localhost:3131/set_session
# show the session
# http://localhost:3131/show_session
# output in browser should show a Session Hash where the count will
# increment for each set_session
