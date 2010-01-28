

class Calmon; class TestResult 
  OK = :ok
  WARNING = :warning
  CRITICAL = :critical
  UNKNOWN = :unknown
  TIMEOUT = :timeout

  attr_accessor :status
  attr_accessor :output

  def initialize
    @status = nil
    @output = nil
  end
end; end # class Calmon::TestResult
