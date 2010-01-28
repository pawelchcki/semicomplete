$: << "./lib"

require 'calmon/models/models.rb'
require 'calmon/scheduler'
require 'calmon/tests/exec'
require 'pp'
require 'yaml'

sched = Calmon::Scheduler.new

conf = YAML::load(File.open("calmond.yaml").read)

entities = []
tests = []
(conf["hosts"] or []).each do |name, data|
  host = Calmon::Models::Host.new(:name => name)

  if data != nil
    host.children += data["services"] if Array === data["services"] 
    host.children += data["hosts"] if Array === data["hosts"] 
    host.tests += data["tests"] if Array === data["tests"] 
  end

  entities << host
end

(conf["services"] or []).each do |name, data|
  service = Calmon::Models::Service.new(:name => name)
  service.children += data["services"] if Array === data["services"] 
  service.children += data["hosts"] if Array === data["hosts"] 
  service.tests += data["tests"] if Array === data["tests"] 

  entities << service
end

(conf["tests"] or []).each do |name, data|
  test = Calmon::Models::Test.new(:name => name)
  test.command = data

  tests << test
end

root = Calmon::Models::Entity.new
#pp entities
entities.each do |entity|
  newchildren = []
  entity.children.each do |child|
    if String === child
      newchildren << entities.select { |e| e.name == child }.first
    else
      newchildren << child
    end
  end
  entity.children = newchildren

  newtests = []
  entity.tests.each do |test|
    if String === test
      newtests << tests.select { |e| e.name == test }.first
    else
      newtests << child
    end
  end
  entity.tests = newtests
end
root.children = entities

def process(schedule, root, parents=[], tests=[])
  (tests + root.tests).each do |test|
    ancestry = parents + [root]
    t = Calmon::Tests::Exec.new( { :interval => (rand * 30).to_i,
                                    :command => test.command,
                                    :parents => ancestry,
                                    :test => test,
                                } )
    have_host = ancestry.any? { |e| Calmon::Models::Host === e }
    have_service = ancestry.any? { |e| Calmon::Models::Service === e }

    puts ancestry.collect { |e| e.name || e.class }.join(", ")
    if (have_host) # and have_service) 
      schedule << t
    end
  end

  if root.children.length > 0
    root.children.each do |entity|
      process(schedule, entity, parents + [root], tests + root.tests)
    end
  end
end

process(sched, root)

sched.run
