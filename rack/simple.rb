#!/usr/bin/env ruby

require 'rubygems'
require 'rack'

my_app = lambda do |env|
  [200, {"Content-Type" => "text/html"}, ["hello world"]]
end

# Rack::Handler::Mongrel.run my_app, :Port => 8888
Rack::Handler::Thin.run my_app, :Port => 8888
# Rack::Handler::WEBrick.run my_app, :Port => 8888

# apachebench
# -n 100 requests
# -n 50 connections/users
# ab -n 100 -c 50 http://localhost:8888/

# curl and show HTTP Request/Response
# curl -vv http://localhost:8888/
