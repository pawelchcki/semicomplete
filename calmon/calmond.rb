$: << "./lib"

require 'rubygems'
require 'calmon/models/models.rb'
require 'calmon/scheduler'
require 'calmon/tests/exec'
require 'dm-core'
require 'pp'
require 'yaml'

#DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.auto_migrate!
sched = Calmon::Scheduler.new
conf = YAML::load(File.open("calmond.yaml").read)

deferred = Hash.new { |h,k| h[k] = Array.new }
entities = []
tests = []
(conf["hosts"] or []).each do |name, data|
  host = Calmon::Models::Host.new(:name => name)
  host.save

  if data != nil
    #address = data["address"] or host.name
    #host.attributes.new(:name => "address", :value => address)
    deferred[[host, :children]] += data["services"] if Array === data["services"] 
    deferred[[host, :children]] += data["hosts"] if Array === data["hosts"] 
    deferred[[host, :tests]] += data["tests"] if Array === data["tests"] 
  end

  entities << host
end

(conf["services"] or []).each do |name, data|
  service = Calmon::Models::Service.new(:name => name)
  service.save

  if data != nil
    deferred[[service, :children]] += data["services"] if Array === data["services"]
    deferred[[service, :children]] += data["hosts"] if Array === data["hosts"] 
    deferred[[service, :tests]] += data["tests"] if Array === data["tests"] 
  end

  entities << service
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
        $STDERR.puts "No such test named '#{name}'!"
        exit 1
      end
      object.tests << realobj
    when :children
      realobj = Calmon::Models::Entity.first(:name => name)
      if realobj == nil
        $STDERR.puts "No such entity (host or service) named '#{name}'!"
        exit 1
      end
      object.children << realobj
    end
  end
  puts "Children: #{object.children.to_a}"
  object.save
end

#root = Calmon::Models::Entity.new
#entities.each do |entity|
  #newchildren = []
  #entity.children.each do |child|
    #if String === child
      #newchildren << entities.select { |e| e.name == child }.first
    #else
      #newchildren << child
    #end
  #end
  #entity.children = newchildren
#
  #newtests = []
  #entity.tests.each do |test|
    #if String === test
      #newtests << tests.select { |e| e.name == test }.first
    #else
      #newtests << child
    #end
  #end
  #entity.tests = newtests
#end
#root.children = entities

def process(schedule, root, depth=0)
  indent = "   " * depth 
  puts "#{indent}#{root.name} #{root.class.name}"

  root.tests.all.each do |test|
    t = Calmon::Tests::Exec.new( { :interval => (rand * 30).to_i,
                                    :command => test.command,
                                    :entity => root,
                                    :test => test,
                                } )
    #have_host = ancestry.any? { |e| Calmon::Models::Host === e }
    #have_service = ancestry.any? { |e| Calmon::Models::Service === e }

    #puts ancestry.collect { |e| e.name || e.class }.join(", ")
    #if (have_host) # and have_service) 
      schedule << t
    #end
  end

  puts root.children.length
  if root.children.length > 0
    root.children.each do |entity|
      process(schedule, entity, depth + 1)
    end
  end
end

Calmon::Models::Entity.all.each do |entity|
  process(sched, entity)
end
sched.run
