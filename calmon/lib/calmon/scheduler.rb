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
      raise ArgumentError.new("#{event.class} has no method 'interval', cannot schedule")
    end

    # TODO(sissel): ADD EVENT HOOK HERE :: EVENT ADDITION
    puts event.class
    schedule(event)
  end # def <<

  def run
    loop do
      # This is probably best implemented as a tree that sorts on 'next run time'
      # like rbtree
      
      # TODO(sissel): Should use a worker-pool model so one test won't
      # block another test from running.
      @events.each do |event, unused|
        start = Time.now
        if start >= event.next_run
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
          result.duration = (Time.now - start).to_f
          result.start_time = start
          event.last_run = start

          record(event, result)
          schedule(event, result)
          sleep(0.2)
        end # if now >= event.next_run
      end # @events.each
      
      sleep(1)
    end
  end # def schedule_runner

  # naive default scheduler. Simply schedules the next time for this event
  # to happen at now + event.interval, unless this is a new event.
  def schedule(event, result=nil)
    if !@events.include?(event)
      @events[event] = true
      # TODO(sissel): HOOK: NEW EVENT
    end
    # TODO(sissel): HOOK: EVENT SCHEDULE
    event.next_run = Time.now + event.interval
  end # def schedule

  def record(event, result)
    tr = Calmon::Models::TestResult.new

    event.sources.each do |source|
      tr.host = source if source.class == Calmon::Models::Host
      tr.class = source if source.class == Calmon::Models::Class
    end
    tr.test = event.dbobj
    tr.status = result.status
    tr.command = result.command
    tr.output = result.output
    tr.duration = result.duration
    tr.start_time = result.start_time
    tr.save

    #puts Calmon::Models::TestResult.all.size
    puts tr
    puts "-" * 80
  end
end; end # class Calmon::Scheduler
