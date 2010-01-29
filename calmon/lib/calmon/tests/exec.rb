require 'calmon/test'
require 'calmon/testresult'

class Calmon; class Tests; class Exec < Calmon::Test
  attr_reader :command
  def initialize(kwds)
    super
    @command = (kwds[:command] or nil)
    @entity = (kwds[:entity] or nil)
    @test = (kwds[:test] or nil)
    @format = (kwds[:format] or nil)
  end # def initialize

  def run
    @last_run = Time.now

    result =  Calmon::TestResult.new
    result.command = @command
    reader, writer = IO.pipe
    # TODO(sissel): can fork throw an exception?
    #require 'pp'
    #puts @parents.collect { |e| e.name or e.class }.join(", ")
    child = fork do
      ENV.update(envhash)
      STDOUT.reopen(writer)
      STDERR.reopen(writer)
      STDIN.close
      reader.close
      exec("/bin/sh", "-c", @command)
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

  def envhash
    env = {}
    ents = []
    x = @entity
    ents << x
    while x.parent != nil
      ents << x
      x = x.parent
    end
    ents << @test

    puts "ENTS::: " + ents.join(", ")
    ents.each do |entity|
      entclass = entity.class.to_s.gsub(/^.*::/, "").upcase
      entity.to_hash.each do |k,v|
        next if v == nil
        env["#{entclass}_#{k.upcase}"] = v
      end
    end
    return env
  end # def envhash

  def procstat_to_status(procstat)
    if procstat.signaled?
      return Calmon::TestResult::UNKNOWN
    end

    case procstat.exitstatus
    when 0
      return Calmon::TestResult::OK
    when 1
      return Calmon::TestResult::WARNING
    when 2
      return Calmon::TestResult::CRITICAL
    else
      return Calmon::TestResult::UNKNOWN
    end
  end # def procstat_to_status
end; end; end # class Calmon::Test::Exec

if $0 == __FILE__
  x = Calmon::Tests::Exec.new({ :interval => 10 })
  puts x.run.inspect
end
