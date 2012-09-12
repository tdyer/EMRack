require 'rubygems'
require 'eventmachine'
require 'evma_httpserver'

# install the gem
# gem install eventmachine_httpserver

# ruby em_httpserver.rb


# NOTE: Everything runs on the Main Reactor Thread!
# No new threads are created! 
class HelloWorld < EM::Connection
  include EM::HttpServer

  def post_init
    puts "HelloWorld#post_init: thread = #{Thread.current}"
    puts "HelloWorld#post_init: establishing a connection with client"
    super
    no_environment_strings
  end

  def process_http_request
    puts "HelloWorld#process_http_request: thread = #{Thread.current}"
    # puts "http_protocol = " << @http_protocol
    # puts "http_request_method = " <<  @http_request_method
    # puts "http_cookie = " <<  @http_cookie if  @http_cookie
    # puts "http_if_not_match = " <<  @http_if_none_match if @http_if_none_match
    # puts "http_content_type = " << @http_content_type if @http_content_type
    # puts "http_path_info = " << @http_path_info
    # puts "http_request_uri = " << @http_request_uri
    # puts "http_query_string = " << @http_query_string if @http_query_string
    # puts "http_post_content = " << @http_post_content.inspect if @http_post_content
    # puts "http_header = " << @http_headers.inspect

    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/html'
    response.content = 'Hello from EventMachine'
    puts "HelloWorld#process_http_request: add a 2 second timer to simulate a blocking call"

    EM.add_timer(2) do
      puts "HelloWorld#process_http_request: sending the HTTP response"
      
      response.send_response
    end
    puts "HelloWorld#process_http_request: DONE!!"
  end
end

puts "Main: thread = #{Thread.current}"

EM.run do
   puts "EM#run: thread = #{Thread.current}"
   puts "EM#run: Starting a HTTP server on port 9292"
  EM.start_server '0.0.0.0', 9292, HelloWorld
end

# ab -n 1 -c 1 http://127.0.0.1:9292/

# when you comment out the puts 
# ab -n 1000 -c 100 http://127.0.0.1:9292/
# Requests per second:    16340.40


# curl -vv  http://127.0.0.1:9292/
