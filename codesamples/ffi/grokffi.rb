require "rubygems"
require "ffi"

module Grok
  extend FFI::Library
  ffi_lib "grok.so"

  # class for grok_t
  # Attributes with '__' prefixes are not for your consumption; they
  # are internal to libgrok.
  class Grok < FFI::Struct
    layout :pattern, :string,
           :pattern_len, :int,
           :full_pattern, :string,
           :full_pattern_len, :int,
           :__patterns, :pointer, # TCTREE*, technically
           :__re, :pointer, # pcre*
           :__pcre_capture_vector, :pointer, # int*
           :__pcre_num_captures, :int,
           :__captures_by_id, :pointer, # TCTREE*
           :__captures_by_name, :pointer, # TCTREE*
           :__captures_by_subname, :pointer, # TCTREE*
           :__captures_by_capture_number, :pointer, # TCTREE*
           :__max_capture_num, :int,
           :pcre_errptr, :string,
           :pcre_erroffset, :int,
           :pcre_errno, :int,
           :logmask, :uint,
           :logdepth, :uint,
           :errstr, :string

    def compile(string)
      Grok.grok_compilen(self, string, string.length)
    end
  end

  class GrokMatch < FFI::Struct

  end

  attach_function :grok_new, [], :pointer
  attach_function :grok_compilen, [:pointer, :string, :int], :int
  attach_function :grok_pattern_add, [:pointer, :string, :int, :string, :int], :int
  attach_function :grok_patterns_import_from_file, [:pointer, :string], :int
  attach_function :grok_execn, [:pointer, :string, :int, :pointer], :int
end


file = File.new("/b/logs/access", "r")
iterations = 500000
require "thread"

queue = Queue.new
(1 .. iterations).each { queue << file.readline() }
start = Time.now

threads = 1.upto(4).collect do
  Thread.new  do
    grok = Grok::Grok.new(Grok.grok_new)
    #grok[:logmask] = (1<<31)-1 # log everything
    pattern = "%{COMBINEDAPACHELOG}"
    Grok.grok_patterns_import_from_file(grok, "/home/jls/projects/grok/patterns/base")
    compiled = Grok.grok_compilen(grok, pattern, pattern.length)
    if compiled != 0
      puts "Error compiling '#{pattern}': #{grok[:errstr]}"
    end

    while true
      break if queue.empty?
      line = queue.pop
      ret = Grok.grok_execn(grok, line, line.size, nil)
    end
  end # Thread.new
end # 1..4

threads.each { |t| t.join }
duration = Time.now - start
p [duration, iterations / duration]
