# -*- coding: utf-8 -*-
require 'rubygems'
require 'rack'

show_env = Proc.new{ |env| [200, { 'Content-Type' => 'text/html'}, [env.inspect]]}

builder = Rack::Builder.new do
  use Rack::CommonLogger # log the request to stdout

  map '/' do
    run show_env
  end
  
  map '/version' do
    map '/last' do
      run Proc.new { |env| [200, { 'Content-Type' => "text/html" }, ["version 4.7"]] }
    end
    # stable version
    map '/' do
      run Proc.new { |env| [200, { 'Content-Type' => "text/html" }, ["version 3.2"]] }
    end
    # first version
    map '/first' do
      run Proc.new { |env| [200, { 'Content-Type' => "text/html" }, ["version 0.2"]] }
    end
  end
  
end

Rack::Handler::Thin.run builder, :Port => 3131

# ruby builder_map.rb
# curl http://localhost:3000
# curl http://localhost:3000/version 
# curl http://localhost:3000/version/last
# curl http://localhost:3000/version/first


