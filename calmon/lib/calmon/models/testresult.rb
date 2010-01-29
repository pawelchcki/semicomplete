
require 'dm-core'

class Calmon; class Models; class TestResult
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :status, String
  property :command, String
  property :output, Text, :lazy => true
  property :duration, Integer
  property :start_time, DateTime, :index => true
  #belongs_to :test
  #belongs_to :host
  #belongs_to :service
end; end; end # class Calmon::Models::TestResult
