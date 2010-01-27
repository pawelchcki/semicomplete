require 'calmon/test'
require 'calmon/testresult'

class Calmon; class Tests; class Exec < Calmon::Test
  def initialize(kwds)
    super
  end # def initialize

  def run
    @last_run = Time.now

    result =  Calmon::TestResult.new
    
    # TODO(sissel): can fork throw an exception?
    child = fork do
      exec("/bin/sh", "-c", "exit 1")
    end

    begin
      pid, procstat = Process.wait2(child)
      result.status = procstat_to_status(procstat)
    rescue Errno::ECHILD => e
      result.status = result.UNKNOWN
    end

    return result
  end # def run

  def procstat_to_status(procstat)
    if procstat.signaled?
      return Calmon::TestResult::UNKNOWN
    end

    case procstat.exitstatus
    when 0
      return Calmon::TestResult::OK
    when 1
      return Calmon::TestResult::WARNING
    when 2
      return Calmon::TestResult::CRITICAL
    else
      return Calmon::TestResult::UNKNOWN
    end
  end # def procstat_to_status

end; end; end # class Calmon::Test::Exec

if $0 == __FILE__
  x = Calmon::Tests::Exec.new({ :interval => 10 })
  puts x.run.inspect
end
