require 'timeout'

class Calmon; class Scheduler
  TIMEOUT = 30

  def initialize(kwds = {})
    @events = {} #RBTree.new
    @queue = []
  end # def initialize

  def <<(event)
    if !event.respond_to?(:interval)
      raise ArgumentError.new("#{event.class} has not method 'interval'")
    end

    # TODO(sissel): ADD EVENT HOOK HERE :: EVENT REGISTER
    @events[event] = Time.now
  end # def <<

  def run
    @runner = Thread.new { schedule_runner }
  end # def run

  def schedule_runner
    loop do
      # This is probably best implemented as a tree that sorts on 'next run time'
      # like rbtree
      
      @events.each do |event, next_time|
        now = Time.now
        if now >= next_time
          puts "running #{event} for #{next_time}\n  (#{now - next_time} seconds behind)"
          result = nil
          begin
            # TODO(sissel): ADD EVENT HOOK HERE :: TEST START
            Timeout.timeout(TIMEOUT) do
              result = event.run
            end # Timeout.timeout
          rescue Timeout::Error => e
            result = Calmon::TestResult.new
            result.status = Calmon::TestResult::TIMEOUT
          end # rescue Timeout::Error

          # TODO(sissel): ADD EVENT HOOK HERE :: TEST END
          @events[event] = now + event.interval

          # sleep a bit between each test
          # This should help space out events, over time, more evenly.
          sleep(0.2)
        end # if now >= next_time
      end # @events.each
      
      sleep(1)
    end
  end # def schedule_runner
end; end # class Calmon::Scheduler

if $0 == __FILE__
  require 'test_exec'
  sched = Calmon::Scheduler.new
  sched << Calmon::Tests::Exec.new( { :interval => 10 } )
  sched << Calmon::Tests::Exec.new( { :interval => 15 } )
  sched.schedule_runner
end
