#!/usr/bin/env ruby

require 'rubygems'
require 'rack'

# create a lamda that will get invoked on /
my_app = lambda do |env|
  title = 'Simple Rack Example with Mongrel And Logging'
  content = ["<html><head><title>#{title}</title><body>",
      "<h1>#{title}</h1>", 
      "<b>Check the command line for logging statements</b></br>", 
      "More content", 
      "</body></html>"
    ]

  # return a simple response
  [200,
    { "Content-Type" => "text/html"},
    content    
  ]
end

# show the filename and the Rack Version
puts File.expand_path(File.dirname(__FILE__))
puts "Rack version = #{Rack.version}"

PORT = 3131
Rack::Handler::Thin.run Rack::CommonLogger.new(my_app), :Port => PORT
# curl http://localhost:3131
