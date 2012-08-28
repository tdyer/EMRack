
# Rack::Session::Cookie.call(env)
#    ...
#   Rack::Session::Abstract::ID.call(env)
#    prepare session
#      add env['rack.session'] = SessionHash.new(self, env)
#      add env['rack.session.options'] = OptionsHash.new(self, env)
#      call next app in chain
#      status, headers, body = app.call(env))

#    commit_session(env, status, headers, body)
#      session = env['rack.session']
#      options = env['rack.session.options']
#      ....
#      
#      SessionHash#load!
#        iff the session hasn't been loaded before
#        Cookie#load_session
#         #this does all the unmarshall and unpack, Base64, of the
#         session hash
#         AND NOW env['rack.session'] is pointed to a ruby hash for the session

# The session data is encoded and encrypted using
# coder = Base64::Marshal.new
# session data is encoded/decoded using Base64::Marshal#encode and #decode
# encode
# [Marshal.dump({:one => 33, 'two' => 'hello'})].pack('m')
# => "BAh7BzoIb25laSZJIgh0d28GOgZFVEkiCmhlbGxvBjsGVA==\n" 
# decode
# ::Marshal.load("BAh7BzoIb25laSZJIgh0d28GOgZFVEkiCmhlbGxvBjsGVA==\n".unpack('m').first)
# => {:one=>33, "two"=>"hello"} 
# used when encrypting session data, @secrets.first is 'change_me'
# "#{session_data}--#{generate_hmac(session_data, @secrets.first)}"

# Simple Rack App that will try to decode/unmarshall session
class SessionDecode
  def initialize(app)
    @app = app
  end
  def call(env)
    cookie = env['HTTP_COOKIE']
    key, value = cookie.split('=')
    # _ourstage_session
    puts "key = #{key}"
    # marshalled and Base64 encoded Hash that represents the Session
    # and digest
    puts "value = #{value}"

    # get the marshalled/encoded hash and digest
    # "#{session_data}--#{generate_hmac(session_data, @secrets.first)}"
    session_data_encoded, digest = value.split('--')
    puts "session_data_encode = #{session_data_encoded.inspect}"

    # unpack, Base64, the session hash
    session_data_unpacked = session_data_encoded.unpack('m')
    puts "session_data_unpacked = #{session_data_unpacked.inspect}"

    # unmarshall the unpacked session hash
    # ArgumentError: dump format error(0x73)
    # ???  maybe a char encoding problem??
    # session_data = ::Marshal.load(session_data_unpacked.first)
    # puts "session_data = #{session_data.inspect}"

    # call next Rack endpoint
    @app.call(env)
  end
end
