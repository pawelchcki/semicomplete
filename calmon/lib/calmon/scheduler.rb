require 'timeout'
require 'calmon/models/testresult'

class Calmon; class Scheduler
  TIMEOUT = 30

  def initialize(kwds = {})
    @events = {} #RBTree.new
    @queue = []
  end # def initialize

  def <<(event)
    if !event.respond_to?(:interval)
      raise ArgumentError.new("#{event.class} has no method 'interval'")
    end

    # TODO(sissel): ADD EVENT HOOK HERE :: EVENT ADDITION
    schedule(event)
  end # def <<

  def run
    loop do
      # This is probably best implemented as a tree that sorts on 'next run time'
      # like rbtree
      
      # TODO(sissel): Should use a worker-pool model so one test won't
      # block another test from running.
      @events.each do |event, next_time|
        now = Time.now
        if now >= next_time
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
          result.duration = Time.now - now
          result.start_time = now

          record(event, result)
          schedule(event, result)
          sleep(0.2)
        end # if now >= next_time
      end # @events.each
      
      sleep(1)
    end
  end # def schedule_runner

  # naive default scheduler. Simply schedules the next time for this event
  # to happen at now + event.interval, unless this is a new event.
  def schedule(event, result=nil)
    # TODO(sissel): ADD EVENT HOOK HERE :: EVENT SCHEDULE
    if @events.include?(event)
      # TODO(sissel): can make scheduling decisions about the next run-time
      # based on the last result.
      @events[event] = Time.now + event.interval
    else
      @events[event] = Time.now
    end
  end # def schedule

  def record(event, result)
    tr = Calmon::Models::TestResult.new
    tr.status = result.status
    tr.command = result.command
    tr.output = result.output
    tr.duration = result.duration
    tr.start_time = result.start_time
    tr.save

    puts Calmon::Models::TestResult.all.size
    puts tr.command
    puts tr.status
    puts tr.output
    puts
  end
end; end # class Calmon::Scheduler
