require "rubygems"
require "eventmachine"
require "eventmachine-tail"
require "ap"

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

def main(args)
  if args.length == 0
    puts "Usage: #{$0} <path_or_glob> [path_or_glob2] [...]"
    return 1
  end

  EventMachine.run do
    handler = EventMachine::FileGlobWatchTail.new(Reader)
    args.each do |path|
      EventMachine::FileGlobWatch.new(path, handler)
    end
  end
end # def main

exit(main(ARGV))
