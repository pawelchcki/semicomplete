class Calmon; class Test #<< Event
  attr_accessor :interval

  # new Calmon::Test
  # arguments are a hash:
  #   :interval => an interval value in seconds
  def initialize(kwds)
    @interval = (kwds[:interval] or nil)
    @last_run = false
  end

end; end # class Calmon::Test
