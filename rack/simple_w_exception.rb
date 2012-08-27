#!/usr/bin/env ruby

require 'rubygems'
require 'rack'

PORT = 3131

# create a lamda that will get invoked on /
my_app = lambda do |env|
  #  raise Exception, "Some new Exception"
  raise "boom"
  
  title = 'Simple Rack Example with Mongrel And Logging'
  content = ["<html><head><title>#{title}</title><body>",
      "<h1>#{title}</h1>", 
      "<b>Check the command line for logging statements</b></br>", 
      "you are just being doppy", 
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
Rack::Handler::Thin.run Rack::ShowExceptions.new(Rack::CommonLogger.new(my_app)), :Port => PORT
