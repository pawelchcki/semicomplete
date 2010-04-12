#!/usr/bin/env ruby

require "rubygems" if __FILE__ == $0
require "set"
require "eventmachine"
require "ap"
require "logger"

require "filetail"

class EventMachine::FileGlobWatch
  def initialize(pathglob, handler, interval=60)
    @pathglob = pathglob
    @handler = handler
    @files = Set.new

    EM.next_tick do
      find_files
      EM.add_periodic_timer(interval) do
        find_files
      end
    end
  end # def initialize

  def find_files
    list = Set.new(Dir.glob(@pathglob))
    list.each do |path|
      next if @files.include?(path)
      watch(path)
    end

    (@files - list).each do |missing|
      @files.delete(missing)
      @handler.file_removed(missing)
    end
  end # def find_files

  def watch(path)
    puts "Watching #{path}"
    @files.add(path)
    @handler.file_found(path)
  end # def watch
end # class EventMachine::FileGlobWatch

class EventMachine::FileGlobWatchHandler
  LOGGER = Logger.new(STDOUT)
  def initialize(handler=nil)
    @handler = handler
  end

  def file_found(path)
    EventMachine::file_tail(path, @handler)
  end

  def file_removed(path)
    # Nothing to do
  end
end # class EventMachine::FileGlobWatchHandler

module EventMachine
  def self.glob_tail(glob, handler=nil, *args)
    handler = EventMachine::FileGlobHandler if handler == nil
    klass = klass_from_handler(EventMachine::FileGlobWatchHandler, handler, *args)
    c = klass.new(*args)
    yield c if block_given?
    return c
  end
end

if __FILE__ == $0
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
    EventMachine::FileGlobWatch.new("/var/log/*.log", EventMachine::FileGlobWatchHandler.new(Reader))
  end
end
