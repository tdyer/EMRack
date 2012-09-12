require 'eventmachine'
class MyDeferrable
  include EM::Deferrable
  def work(str)
    puts "MyDeferrable#work: #{ Thread.current}"
    puts "MyDeferrable#work: Doing work #{str}"
    puts "MyDeferrable#work: Done work, fire callback"
    set_deferred_status :succeeded, str
  end
end

EM.run do
  df = MyDeferrable.new
  puts "Main thread = #{  Thread.current}"

  # These callbacks will be called by 
  # set_deferred_status :succeeded in the MyDeferrable#work method
  
  # Callback 1
  df.callback do |param|
    puts "MyDeferrable: callback 1, thread = #{Thread.current}"
    puts "MyDeferrable: callback 1, param = #{param}"
    df.set_deferred_status :succeeded, "cb1 -> " << param
  end

  # Callback 2
  df.callback do |param|
    puts "MyDeferrable: callback 2, thread = #{ Thread.current}"
    puts "MyDeferrable: callback 2, param = #{param}"
    df.set_deferred_status :succeeded, "cb2 -> " << param
  end

  # Callback 3, will stop reactor
  df.callback do |param|
    puts "MyDeferrable: callback 3, thread = #{Thread.current}"
    puts "MyDeferrable: callback 3, param = #{param}"
    puts "MyDeferrable: callback 3, add_timer to fire in 3 seconds" 
    EM.add_timer(3) do
      puts "MyDeferrable: callback 3, DO WORK !!!!!"
      puts "MyDeferrable: callback 3, STOP REACTOR!!!!"
      EM.stop
    end
  end

  # fire a timer in 1 second that will exec the block
  EM.add_timer(1) do
    puts "add_timer #{ Thread.current}"
    df.work("chug, chug, chug")
  end

  puts "End of Reactor Loop!!!"
end
puts "End of Main Thread, See ya"

# NOTE: everything runs on 1 thread!!
# ruby deferrable1.rb 
# Main thread = #<Thread:0x007fb7290699a0>
# End of Main Thread!!!
# add_timer #<Thread:0x007fb7290699a0>
# MyDeferrable#work: #<Thread:0x007fb7290699a0>
# MyDeferrable#work: Doing work chug, chug, chug
# MyDeferrable#work: Done work, fire callback
# MyDeferrable: callback 1, thread = #<Thread:0x007fb7290699a0>
# MyDeferrable: callback 1, param = chug, chug, chug
# MyDeferrable: callback 2, thread = #<Thread:0x007fb7290699a0>
# MyDeferrable: callback 2, param = cb1 -> chug, chug, chug
# MyDeferrable: callback 3, thread = #<Thread:0x007fb7290699a0>
# MyDeferrable: callback 3, param = cb2 -> cb1 -> chug, chug, chug
# MyDeferrable: callback 3, add_timer to fire in 3 seconds
# MyDeferrable: callback 3, DO WORK !!!!!
# MyDeferrable: callback 3, STOP REACTOR!!!!
