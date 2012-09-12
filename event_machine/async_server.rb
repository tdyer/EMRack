#!/usr/bin/env ruby

# http://www.igvita.com/2008/05/27/ruby-eventmachine-the-speed-demon/

require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'

# install the gem
# gem install eventmachine_httpserver

# to run:
# async_server.rb

# 5 clients each making 2 requests
# ab -n 10 -c 5 http://127.0.0.1:9292/

class SimpleASyncHandler < EM::Connection
  include EM::HttpServer

  def post_init
    puts "SimpleASyncHandler#post_init: establishing a connection with client, thread = #{Thread.current}"
    super
  end

  def process_http_request
    puts "SimpleASyncHandler#process_http_request: BEGIN"
    response = EM::DelegatedHttpResponse.new(self)

    http = EM::Protocols::HttpClient.request(:host=>"127.0.0.1", :port=>3333,:request=>"/" )

    # setup callback handler, when the client responds
    http.callback do |reply|
      puts "SimpleASyncHandler#process_http_request: responding in the callback"
      response.status = 200
      response.content_type 'text/html'
      response.content = reply[:content]
      response.send_response
    end
    
    puts "SimpleASyncHandler#process_http_request: DONE"
  end
end

EM.run do
  puts "EM#run: thread = #{Thread.current}"
  puts "EM#run: Starting a HTTP server on port 8011"
  EM.start_server '0.0.0.0', 8011, SimpleASyncHandler
end
