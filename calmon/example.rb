require 'calmon/scheduler'
require 'calmon/tests/exec'

sched = Calmon::Scheduler.new
sched << Calmon::Tests::Exec.new( { :interval => 10 } )
sched << Calmon::Tests::Exec.new( { :interval => 15 } )
sched.schedule_runner
