#!/usr/bin/env ruby
require 'timeout'

if ARGV.length < 2
  STDERR.puts "Usage: #{$0} <timeout> command ..."
  exit 1
end

timeout = ARGV[0].to_f
cmd = ARGV[1..-1]

pid = nil
begin
  Timeout.timeout(timeout) do
    pid = fork do
      exec(*cmd);
      exit 1 # in case exec() fails
    end
    Process.waitpid(pid)
    pid = nil
    exit $?.exitstatus
  end
rescue Timeout::Error
  STDERR.puts "Execution expired (timeout == #{timeout})"
  # kill the process if it's still alive.
  if pid
    Process.kill('TERM', pid)
  end
  exit 254
end

