

class Calmon; class TestResult 
  OK = :ok
  WARNING = :warning
  CRITICAL = :critical
  UNKNOWN = :unknown
  TIMEOUT = :timeout

  attr_accessor :status
  attr_accessor :output
  attr_accessor :command
  attr_accessor :duration
  attr_accessor :start_time

  def initialize
    @status = nil
    @output = nil
    @command = nil
    @duration = nil
    @start_time = nil
  end
end; end # class Calmon::TestResult
