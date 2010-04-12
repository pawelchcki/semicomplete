#!/usr/bin/env ruby

require "rubygems" if __FILE__ == $0
require "eventmachine"
require "logger"

EventMachine.epoll if EventMachine.epoll?

class EventMachine::FileTail
  CHUNKSIZE = 65536 
  MAXSLEEP = 2

  attr_reader :path

  public
  def initialize(path, startpos=0)
    @path = path
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::WARN

    #@need_scheduling = true
    open

    @fstat = File.stat(@path)
    @file.sysseek(0, IO::SEEK_END)
    watch
  end # def initialize

  public
  def notify(status)
    @logger.debug("#{status} on #{path}")
    if status == :modified
      schedule_next_read
    elsif status == :moved
      # TODO(sissel): read to EOF, then reopen.
      open
    end
  end

  private
  def open
    @file.close if @file
    begin
      @file = File.open(@path, "r")
    rescue Errno::ENOENT
      # no file found
      raise
    end

    @naptime = 0;
    @pos = 0
    schedule_next_read
  end

  private
  def watch
    EventMachine::watch_file(@path, FileWatcher, self)
  end

  private
  def schedule_next_read
    EventMachine::add_timer(@naptime) do
      read
    end
  end

  private
  def read
    begin
      data = @file.sysread(CHUNKSIZE)
      # Won't get here if sysread throws EOF
      @pos += data.length
      @naptime = 0
      receive_data(data)
      schedule_next_read
    rescue EOFError
      eof
    end
  end

  private
  def eof
    # TODO(sissel): This will be necessary if we can't use inotify or kqueue to
    # get notified of file changes
    #if @need_scheduling
      #@naptime = 0.100 if @naptime == 0
      #@naptime *= 2
      #@naptime = MAXSLEEP if @naptime > MAXSLEEP
      #@logger.info("EOF. Naptime: #{@naptime}")
    #end

    # TODO(sissel): schedule an fstat instead of doing it now.
    fstat = File.stat(@path)
    handle_fstat(fstat)
  end # def eof

  private
  def handle_fstat(fstat)
    if (fstat.ino != @fstat.ino)
      open # Reopen if the inode has changed
    elsif (fstat.rdev != @fstat.rdev)
      open # Reopen if the filesystem device changed
    elsif (fstat.size < @fstat.size)
      @logger.info("File likely truncated... #{path}")
      @file.sysseek(0, IO::SEEK_SET)
      schedule_next_read
    end
    @fstat = fstat
  end # def eof
end # class EventMachine::FileTail

# Internal usage only
class EventMachine::FileTail::FileWatcher < EventMachine::FileWatch
  def initialize(filestream)
    @filestream = filestream
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::WARN
  end

  def file_modified
    @filestream.notify :modified
  end

  def file_moved
    @filestream.notify :moved
  end

  def file_deleted
    @filestream.notify :deleted
  end

  def unbind
    @filestream.notify :unbind
  end
end # class EventMachine::FileTail::FileWatch < EventMachine::FileWatch

# Add EventMachine::file_tail
module EventMachine
  def self.file_tail(path, handler=nil, *args)
    args.unshift(path)
    klass = klass_from_handler(EventMachine::FileTail, handler, *args);
    c = klass.new(*args)
    yield c if block_given?
    return c
  end # def self.file_tail
end # module EventMachine
