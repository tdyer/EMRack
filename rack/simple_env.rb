#!/usr/bin/env ruby

require 'rubygems'
require 'rack'

# create a lamda that will get invoked on /
my_app = lambda do |env|

  # print out environment variables passed, contructed by the web
  # server from the HTTP request
  begin
    puts
    puts '*'*10 << " Environment:" << '*'*10
    env.each do |k, v|
      puts "#{k}: #{v}"
    end
  end

  title = 'Simple Rack Example to print out path and some environment variables'
  content = ["<html><head><title>#{title}</title><body>",
             "<h1>#{title}</h1>", 
             "Nothing to say really!!!",
             "<h3>The path you're looking for is <i>  #{env['PATH_INFO']}  </i></h3>",
             "</body></html>"
            ]

  # return a simple response
  [200,
   { "Content-Type" => "text/html"},
   content    
  ]
end

puts File.expand_path(File.dirname(__FILE__))

puts "Rack version = #{Rack.version}"

PORT = 8111
# Rack::Handler::WEBrick.run Rack::CommonLogger.new(my_app), :Port => PORT
Rack::Handler::WEBrick.run my_app, :Port => PORT

# client
# curl http://localhost:8111 -v
# OR
# ab -n 1 -c 1 http://127.0.0.1:8111/
