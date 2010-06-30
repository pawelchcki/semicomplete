#!/usr/bin/env ruby
# TODO(sissel): support nesting and array indexing in 'key'
# Converting the JSON object to xml and permitting xpath would be nice
# For example: foo/bar[0]/baz will fetch
# { "foo": { "bar" : [ { "baz": 3 }, foo ] } } 
# and get you: 3
# Or something...

require "yaml"
require "json"
require "time"
require "date"

# Backport Ruby 1.9 feature
if (!Time.respond_to?("strptime"))
  class Time
    def self.strptime(datestr, format)
      d = Date._strptime(datestr, format)
      raise ArgumentError, "invalid strptime format - `#{format}'" unless d
      make_time(d[:year], d[:mon], d[:mday], d[:hour], d[:min], d[:sec],
                d[:sec_fraction], d[:zone], now)
    end
  end
end

class ReactorData
  attr_accessor :timestamp
  attr_accessor :input
end

class TimeParserError < RuntimeError; end

class TimeParser
  attr_accessor :format
  attr_accessor :key

  def initialize(format, key)
    @format = format
    @key = key
  end

  def parse(input)
    if !input.has_key?(@key)
      raise TimeParserError, "Input has no timestamp key '#{@key}'"
    end
    #puts "Parsing #{input[@key]} with '#{@format}'"
    t = Time.strptime(input[@key], @format)
    return t
  end
end

class Reactor
  attr_accessor :action
  attr_accessor :interval
  attr_accessor :keys
  attr_accessor :threshold
  attr_accessor :round_time_to_interval

  def initialize(config)
    @action = config["action"]
    @interval = config["interval"].to_i
    # TODO(sissel): Accept yaml sequence, too, for keys?
    @keys = config["key"].split(",")
    @threshold = config["threshold"].to_i
    @round_time_to_interval = config["timestamp-round"].to_i

    if config.has_key?("timestamp-key")
      @timeparser = TimeParser.new(config["timestamp-format"],
                                   config["timestamp-key"])
    else
      @timeparser = nil
    end

    #@history = HistoryTracker.new
    @history = Hash.new { |h,k| h[k] = [] }
    @value = Hash.new { |h,k| h[k] = 0 }

    @@counter = 0
  end

  def feed(input)
    return unless @keys.collect { |k| input.has_key?(k) }.reduce { |a,b| a & b }
    filtered_input = process(input)
    key = keygen(filtered_input)

    rd = ReactorData.new
    rd.input = input
    rd.timestamp = @timeparser ? @timeparser.parse(input) : Time.now
    #puts input["@LINE"]
    #puts "#{@value[key]}: #{key.inspect}"

    # If we hit interval, react on this key exactly as if we had hit the
    # threshold.
    trimtime = rd.timestamp - @interval

    if (@threshold == 0 && @interval > 0)
      # Check all entries for interval expiration
      @history.each do |histkey,histdata| 
        lastentry = histdata[-1]
        if lastentry && lastentry.timestamp < trimtime
          react(keygen(process(lastentry.input)), lastentry.timestamp)
        end
      end
    else
      trim_history(key, trimtime)
    end

    @value[key] += 1
    threshold_exceeded = ((@threshold > 0) and (@value[key] >= @threshold))
    #puts [threshold_exceeded, @threshold, @value[key]].join(" / ")
    if (threshold_exceeded)
      react(key, rd.timestamp)
    end

    @@counter += 1
    if @@counter > 1000
      @history.each do |histkey,histdata|
        trim_history(histkey, trimtime)
      end
      @@counter = 0 
    end
    @history[key] << rd
  end

  def trim_history(key, trimtime)
    histdata = @history[key]
    while histdata.length > 0 && histdata[0].timestamp < trimtime
      k = process(keygen(histdata[0].input))
      @value[k] -= 1
      histdata.shift
    end
  end

  def react(key, timestamp=nil)
    timestamp = Time.now unless timestamp
    if @round_time_to_interval
      etime = timestamp.to_i
      timestamp = Time.at(etime - (etime % @interval))
    end
    #puts "Threshold exceeded: #{@value[key]} > #{@threshold}"
    $stderr.puts "#{@value[key]}: #{key.inspect} / #{timestamp}"
    value = @value[key]

    eval("puts \"#{@action}\"")
    $stdout.flush
    @value[key] = 0
    @history[key].clear
  end

  def process(input)
    # make a new object with only the 'keys' key:value pairs present.
    input = Hash[*keys.collect { |k| [k, input[k]] }.flatten ]
    return input
  end

  def keygen(input)
    #@keys.collect { |k| input[k] }
    input
  end
end

config = YAML::load(File.new("reactor.yaml").read)

data = Hash.new { |h,k| h[k] = [] }

reactors = []
config.each do |c|
  r = Reactor.new(c)
  reactors << r
end

$stdin.each do |line|
  obj = JSON.parse(line)
  reactors.each { |r| r.feed(obj) }
end
