require 'calmon/test'
require 'calmon/models/testresult'

class Calmon; class Tests; class Exec < Calmon::Test
  attr_reader :command
  def initialize(kwds)
    super
    @command = (kwds[:command] or nil)
    @format = (kwds[:format] or nil)
    @debug = (kwds[:debug] or false)
  end # def initialize

  def run
    @last_run = Time.now

    result =  Calmon::Models::TestResult.new
    result.command = @command
    reader, writer = IO.pipe
    # TODO(sissel): Catch any exception thrown by fork?
    child = fork do
      ENV.update(envhash)
      STDOUT.reopen(writer)
      STDERR.reopen(writer)
      STDIN.close
      reader.close
      # This may throw an exception if /bin/sh doesn't exist, but
      # that exception should cause ruby to exit nonzero.
      args = [ "/bin/sh" ]
      args << "-x" if @debug
      args << "-c"
      args << @command
      exec(*args)
    end
    writer.close
    result.output = reader.read

    begin
      pid, procstat = Process.wait2(child)
      result.status = procstat_to_status(procstat)
    rescue Errno::ECHILD => e
      result.status = result.UNKNOWN
    end

    return result
  end # def run

  private
  def envhash
    env = {}
    ents = []

    @sources.each do |entity|
      entclass = entity.class.to_s.gsub(/^.*::/, "").upcase
      entity.to_hash.each do |k,v|
        next if v == nil
        env["#{entclass}_#{k.upcase}"] = v
      end
    end
    return env
  end # def envhash

  private
  def procstat_to_status(procstat)
    if procstat.signaled?
      return Calmon::Models::TestResult::UNKNOWN
    end

    case procstat.exitstatus
    when 0
      return Calmon::Models::TestResult::OK
    when 1
      return Calmon::Models::TestResult::WARNING
    when 2
      return Calmon::Models::TestResult::CRITICAL
    else
      return Calmon::Models::TestResult::UNKNOWN
    end
  end # def procstat_to_status
end; end; end # class Calmon::Test::Exec
