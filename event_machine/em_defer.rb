require 'eventmachine'
require 'thread'

EM.run do
  puts "Main: thread #{  Thread.current}"
  
  EM.add_timer(2) do
    # runs in the main reactor loop
    puts "EM.add_timer: thread #{  Thread.current}"
    EM.stop_event_loop
  end
  
  EM.defer do
    # runs in a new thread
    puts "EM#defer: block 1, thread =  #{Thread.current}"
    EM.defer do
      # runs in the same thread as block 1
      puts "EM#defer: block 1.2, thread =  #{Thread.current}"      
    end
  end
  EM.defer do
    # runs in a new thread
    puts "EM#defer: block 2, thread =  #{Thread.current}"      
  end
end  


# Each new EM.defer invoked in the main reactor thread creates a new
# thread to run in!
# Nested EM.defer blocks do NOT create a new thread to run in. They
# run in their parent's thread!

# ruby em_defer.rb 
# Main: thread #<Thread:0x007f80f10699a0>
# EM#defer: block 1, thread =  #<Thread:0x007f80f20f02d8>
# EM#defer: block 2, thread =  #<Thread:0x007f80f20f02d8>
# EM#defer: block 1.2, thread =  #<Thread:0x007f80f20f02d8>
# EM.add_timer: thread #<Thread:0x007f80f10699a0>
