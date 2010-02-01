$: << "./lib"

require 'rubygems'
require 'calmon/models/models'
require 'calmon/scheduler'
require 'calmon/tests/exec'
require 'dm-core'
require 'pp'
require 'yaml'

#DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, 'sqlite3:calmond.db')
#DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.auto_migrate!
sched = Calmon::Scheduler.new
conf = YAML::load(File.open("calmond.yaml").read)

deferred = Hash.new { |h,k| h[k] = Array.new }
entities = []
tests = []
(conf["hosts"] or []).each do |name, data|
  host = Calmon::Models::Host.new(:name => name)

  if data != nil
    address = data["address"]
    host.address = address
    #host.attributes.new(:name => "address", :value => address)
    deferred[[host, :classes]] += data["classes"] if Array === data["classes"] 
    #deferred[[host, :children]] += data["hosts"] if Array === data["hosts"] 
    deferred[[host, :tests]] += data["tests"] if Array === data["tests"] 
  end

  host.save
  entities << host
end

(conf["classes"] or []).each do |name, data|
  puts "Class: #{name}"
  oclass = Calmon::Models::Class.new(:name => name)
  oclass.save

  if data != nil
    if data.class != Hash
      STDERR.puts "Bad data for class #{name}. Expected Hash, got #{data.class}"
      exit 1
    end
    deferred[[oclass, :classes]] += data["classes"] if Array === data["classes"]
    #deferred[[oclass, :children]] += data["hosts"] if Array === data["hosts"] 
    deferred[[oclass, :tests]] += data["tests"] if Array === data["tests"] 
  end

  entities << oclass
end

(conf["tests"] or []).each do |name, data|
  test = Calmon::Models::Test.new(:name => name)
  test.command = data
  test.save

  tests << test
end

deferred.each do |key, deferredlist|
  object, method = key
  deferredlist.each do |name|
    realobj = nil
    case method
    when :tests
      realobj = Calmon::Models::Test.first(:name => name)
      if realobj == nil
        STDERR.puts "No such test named '#{name}'!"
        exit 1
      end
      object.tests << realobj
    #when :children
      #realobj = Calmon::Models::Host.first(:name => name)
      #if realobj == nil
        #STDERR.puts "No such host) named '#{name}'!"
        #exit 1
      #end
      #object.children << realobj
    when :classes
      realobj = Calmon::Models::Class.first(:name => name)
      if realobj == nil
        STDERR.puts "No such host) named '#{name}'!"
        exit 1
      end
      puts "Adding #{realobj.name} to host #{object.name}"
      object.classes << realobj
    end # case method
  end # deferredlist.each 
  object.save
end

def process(schedule, root, ancestors=[], depth=0)
  indent = "   " * depth 
  puts "#{indent}#{root.name} #{root.class.name}"

  root.tests.all.each do |test|
    t = Calmon::Tests::Exec.new( { :interval => (rand * 30).to_i,
                                    :command => test.command,
                                    :entity => root,
                                    :sources => ancestors + [root],
                                    :dbobj => test,
                                } )
    schedule << t
  end

  if root.respond_to?(:classes)
    root.classes.each do |classobj|
      process(schedule, classobj, ancestors + [root], depth + 1)
    end
  end
end

Calmon::Models::Host.all.each do |host|
  process(sched, host)
end

def foo(entity, depth=0)
  d = "   " * depth
  puts "#{d} #{entity.name}"
  entity.tests.each do |test|
    puts "#{d} => T : #{test.name}"
  end
  if entity.respond_to?(:classes)
    entity.classes.each do |e|
      foo(e, depth + 1)
    end
  end
end

Calmon::Models::Host.all.each do |entity|
  foo(entity)
end

#pp sched
sched.run
