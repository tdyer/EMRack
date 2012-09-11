%w(rubygems rack).each {  |dep| require dep }

class OneApp
  def call(env)
    [200, {"Content-Type"=> "text/plain"}, ["One App"]]
  end
end

class TwoApp
  def call(env)
    [200, {"Content-Type"=> "text/plain"}, ["Two App"]]
  end
end

use Rack::ShowExceptions
use Rack::CommonLogger

map '/one_app' do
  run OneApp.new
end

map '/two_app' do
  run TwoApp.new
end

#  thin --rackup my_rackup.ru start -p 8111
