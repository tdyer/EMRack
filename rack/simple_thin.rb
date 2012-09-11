#!/usr/bin/env ruby

require 'rubygems'
require 'rack'
require 'thin'


app =  lambda do |env|
  [200, {"Content-Type" => "text/html"}, ["hello Thin world"]]
end

Thin::Server.start('0.0.0.0', 8888) do
  run app
end

# apachebench
# -n 100 requests
# -n 50 connections/users
# ab -n 100 -c 50 http://localhost:8888/

# curl and show HTTP Request/Response
# curl -vv http://localhost:8888/
