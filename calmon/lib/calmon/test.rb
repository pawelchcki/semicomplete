require 'calmon/event'

class Calmon; class Test < Calmon::Event
  attr_accessor :interval
  attr_accessor :sources
  attr_accessor :dbobj

  # new Calmon::Test
  # arguments are a hash:
  #   :interval => an interval value in seconds
  def initialize(kwds)
    super
    @interval = (kwds[:interval] or nil)
    @sources = (kwds[:sources] or nil)
    @dbobj = (kwds[:dbobj] or nil)
    @last_run = false
  end
end; end # class Calmon::Test
