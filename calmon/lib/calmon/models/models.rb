#require 'dm-core'

class Calmon; class Models; class Entity
  attr_accessor :name
  attr_accessor :children
  attr_accessor :tests

  def initialize(kwds = {})
    @name = (kwds[:name] or nil)
    @children = []
    @tests = []
  end

  def to_hash
    return { "name" => @name }
  end
end; end; end # class Calmon::Models::Entitty

class Calmon::Models::Host < Calmon::Models::Entity
end

class Calmon::Models::Service < Calmon::Models::Entity
end

class Calmon; class Models; class Test
  attr_accessor :name
  attr_accessor :command
  attr_accessor :interval

  def initialize(kwds = {})
    @name = (kwds[:name] or nil)
    @command = (kwds[:command] or nil)
  end

end; end; end # class Calmon::Models::Tests

