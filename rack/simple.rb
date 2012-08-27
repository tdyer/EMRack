#!/usr/bin/env ruby

require 'rubygems'
require 'rack'

my_app = lambda do |env|
  [200, {"Content-Type" => "text/html"}, ["hello world"]]
end

# Rack::Handler::Mongrel.run my_app, :Port => 8888
# Rack::Handler::Thin.run my_app, :Port => 8888
Rack::Handler::WEBrick.run my_app, :Port => 8888
