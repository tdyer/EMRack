require 'rubygems'
require 'rack'

PORT = 3131


# Download Files
# http://localhost:3131/foo
# http://localhost:3131/rails.png
# http://localhost:3131/SoftwareArticle.pdf

#app = Rack::File.new('.')
app = Rack::CommonLogger.new(Rack::File.new('.'))
#app = Rack::ShowExceptions.new(app)
#app = Rack::ShowStatus.new(app)

puts "Starting up on PORT #{PORT}"
puts "Rack version = #{Rack.version}"
Rack::Handler::Thin.run Rack::ShowStatus.new(Rack::ShowExceptions.new(Rack::CommonLogger.new(Rack::File.new('.')))), :Port => PORT

