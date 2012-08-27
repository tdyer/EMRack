#!/usr/bin/env ruby
# -*- ruby -*-

require 'rubygems'
require 'rack'

PORT = 3131
title = 'Simple Rack Example with URL Mappings'
header = "<html><head><title>#{title}</title></head>"
footer = "</body></html>"

# Create three Proc/Lambda's
first_app, second_app, third_app = %w{ First Second Third}.collect do |appname|
  lambda do |env|
    body = "<h1>#{appname} Application</h1>"
    [200, { "Content-Type" => "text/html"}, [header, body, footer] ]
  end
end


bogus_app = lambda do |env|
  raise "Invalid URL, baaaaby"
end

# Map each of the above Procs to a URL
# http://localhost:3131/one_app to the first Proc
# http://localhost:3131/second_app to the second Proc
# http://localhost:3131/third_app to the third Proc...
# Any other URL will be handled by the bogus_app Proc which will raise an Exception 
Rack::Handler::Thin.run Rack::ShowExceptions.new(Rack::CommonLogger.new(Rack::URLMap.new('/one_app'=> first_app, '/two_app' => second_app,'/three_app' => third_app, '/' => bogus_app))), :Port => PORT

