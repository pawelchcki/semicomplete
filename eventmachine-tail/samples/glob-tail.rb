require "rubygems"
require "eventmachine"
require "eventmachine-tail"
require "awesome_print"

class Reader < EventMachine::FileTail
  def initialize(*args)
    super(*args)
    @buffer = BufferedTokenizer.new
  end

  def receive_data(data)
    @buffer.extract(data).each do |line|
      ap [path, line]
    end
  end
end

EventMachine.run do
  EventMachine::FileGlobWatch.new("/var/log/*.log",
                                  EventMachine::FileGlobWatchHandler.new(Reader))
end

