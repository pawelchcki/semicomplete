
require 'dm-core'

class Calmon; class Models; class TestResult
  include DataMapper::Resource
  OK = :ok
  WARNING = :warning
  CRITICAL = :critical
  UNKNOWN = :unknown
  TIMEOUT = :timeout

  property :id, Serial, :key => true
  property :status, String
  property :command, String
  property :output, Text, :lazy => true
  property :duration, Float
  property :start_time, DateTime, :index => true
  belongs_to :test
  belongs_to :host
  belongs_to :class

  def to_s
    data = []
    data << "Host: #{@host}"
    data << "Class: #{@class}"
    data << "Test: #{@test}"
    data << "Command: #{@command}"
    data << "Status: #{@status}"
    data << "Duration: #{@duration}"
    data << "Start time: #{@start_time}"
    data << "Output:"
    data << @output
    return data.join("\n")
  end # def to_s
end; end; end # class Calmon::Models::TestResult
