#!/usr/bin/env ruby

require 'rubygems'
require 'rack'

PORT = 3131

# Override to log to stdout instead of env["rack.errors"]
# see commonlogger.rb
module Rack
  class CommonLogger
    def <<(str)
      $stdout.write(str)
      $stdout.flush
    end
  end
end

# create a lamda that will get invoked on /
my_app = lambda do |env|
  puts
  puts '*'*10 << " Environment:" << '*'*10
  env.each do |k, v|
    puts "#{k}: #{v}"
  end
  title = '*'*10 << " HTTP Request from Rack" << '*'*10
  env_html = ""
  env_pairs = env.each do |k, v|
    env_html << "<li> <b>Key:</b> #{k.inspect} <b>Value:</b> #{v.inspect} </li>"
  end
  puts "env_pairs = #{env_pairs.inspect}"
  puts "env_html = #{env_html.inspect}"
  
  request = Rack::Request.new(env)
  # filter out some methods
  meths = Rack::Request.instance_methods(false) - ['values_at', '[]', '[]=', 'script_name=','path_info=']

  # build the html for request method output
  # req_html = request.inspect
  req_html = ""
  meths.map.each{ |m| m.to_sym}.each do |m| 
    req_html << "<li> <b>Method:</b> #{m}" #" <b>Value:</b> #{request.send(m).inspect} </li>"
  end

  content = <<-ENV_HTML
    <html><head><title>#{title}</title>
    <body>
    <h1>#{title}</h1>
    <ul> <h3>ENV</h3> #{env_html}</ul>
    <ul> <h3>RACK REQUEST</h3> #{req_html}</ul>
    </body>
    </html>
  ENV_HTML
  puts "content = #{content.inspect}"

  # return a simple response
  [200,
    { "Content-Type" => "text/html"},
    [content]    
  ]
end

puts File.expand_path(File.dirname(__FILE__))

puts "Rack version = #{Rack.version}"

#Rack::Handler::WEBrick.run Rack::CommonLogger.new(my_app), :Port => PORT
Rack::Handler::Thin.run Rack::CommonLogger.new(my_app), :Port => PORT
# curl http://localhost:3131
