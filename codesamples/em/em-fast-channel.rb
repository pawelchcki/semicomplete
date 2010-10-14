require "rubygems"
require "thread"
require "eventmachine"

module EventMachine
  # A faster Channel class that uses a file descriptor to signal
  # EventMachine of new data rather than using EventMachine.schedule (which
  # uses a timer under the hood)
  #
  # Should be threadsafe.
  class FastChannel < EventMachine::Channel

    class Reader < EventMachine::Connection
      def initialize(channel)
        super()
        @channel = channel
      end

      def notify_readable
        @channel.notify_readable
      end # def notify_readable
    end

    def initialize
      @reader, @writer = IO.pipe
      @uid = 0
      @queue = ::Queue.new   # use thread's Queue, not EventMachine's
      @subscription_lock = Mutex.new
      @subscriptions = {}
      @watcher = EventMachine.watch(@reader, Reader, self)
      @watcher.notify_readable = true
      @watcher.notify_writable = false
    end # def initialize

    def subscribe(*a, &b)
      name = nil
      @subscription_lock.synchronize do
        name = @uid
        @uid += 1
        @subscriptions[name] = EventMachine::Callback(*a, &b)
      end
      return name
    end # def subscribe

    def unsubscribe(name)
      @subscription_lock.synchronize do
        @subscriptions.delete name
      end
    end # def unsubscribe

    def push(*items)
      puts "Pushing: #{items}"
      items.each { |item| @queue << item }
      # TODO(sissel): write one signal per item?
      @writer.syswrite("1")
      #@writer.flush
    end

    def pop
      # TODO(sissel): Implement
      raise NotImplementedError("#{self.class.name}#pop is not supported")
    end

    def notify_readable
      while !@queue.empty?
        item = @queue.pop

        @subscription_lock.synchronize do
          subscriptions = @subscriptions.values
        end

        @subscriptions.values.each do |callback|
          callback.call item
        end
      end # while !@queue.empty?
    end # def notify_readable
  end # class FastChannel
end # module EventMachine

if $0 == __FILE__
  queue = Queue.new
  EventMachine.schedule do
    channel = EventMachine::FastChannel.new
    channel.subscribe do |item| 
      queue << item 
    end
    EventMachine.add_periodic_timer(1) { 
      puts "Adding item"
      channel.push(Time.now) 
    }
  end
  Thread.new { EventMachine.run }

  while true
    item = queue.pop
    puts "Delay: #{Time.now - item}"
  end

end
