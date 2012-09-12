#!/usr/bin/env ruby

# http://www.igvita.com/2008/05/27/ruby-eventmachine-the-speed-demon/

require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'
require 'httpclient'

# install the gem
# gem install eventmachine_httpserver

# to run:
# sync_server.rb

# 5 clients each making 2 requests
# ab -n 10 -c 5 http://127.0.0.1:9292/

class SimpleSyncHandler < EM::Connection
  include EM::HttpServer

  def post_init
    puts "SimpleSyncHandler#post_init: establishing a connection with client, thread = #{Thread.current}"
    super
  end

  def process_http_request
    puts "SimpleSyncHandler#process_http_request:"
    response = EM::DelegatedHttpResponse.new(self)
    # sleep(2)
    # Block waiting for each HTTP reply
    HTTPClient.new().get('http://127.0.0.1:3333/')
    response.status = 200
    response.content_type 'text/html'
    response.content = 'Hello from EventMachine'
    response.send_response
  end
end

EM.run do
  puts "EM#run: thread = #{Thread.current}"
  puts "EM#run: Starting a HTTP server on port 8010"
  EM.start_server '0.0.0.0', 8010, SimpleSyncHandler
end
