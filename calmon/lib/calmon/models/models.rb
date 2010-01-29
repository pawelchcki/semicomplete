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
  attr_accessor :address

  def initialize(kwds = {})
    super
    @address = (kwds[:address] or @name)
  end # def initialize

  def to_hash
    return super.merge({
      "address" => @address
    })
  end
end # class Calmon::Models::Host

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

  def to_hash
    return {
      "name" => @name,
      "command" => @command,
      "interval" => @interval,
    }
  end

end; end; end # class Calmon::Models::Tests

