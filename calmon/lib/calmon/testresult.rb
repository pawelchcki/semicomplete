

class Calmon; class TestResult 
  OK = :ok
  WARNING = :warning
  CRITICAL = :critical
  UNKNOWN = :unknown
  TIMEOUT = :timeout

  attr_accessor :status

  def initialize
    @status = nil
  end
end; end # class Calmon::TestResult
