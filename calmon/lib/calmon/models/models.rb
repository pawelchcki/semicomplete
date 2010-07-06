require 'dm-core'

class Calmon::Models::Host
  include DataMapper::Resource

  property :name, String, :key => true
  property :address, String, :required => false
  has n, :tests, :through => Resource
  has n, :classes, :through => Resource

  def to_hash
    return { 
      "name" => @name,
      "address" => (@address or @name)
    }
  end

  def to_s
    if ![nil, @name].include?(@address)
      return "#{@name} (#{@address})"
    end
    return @name
  end # def to_s
end # class Calmon::Models::Entitty

class Calmon::Models::Class
  include DataMapper::Resource

  property :name, String, :key => true
  has n, :tests, :through => Resource

  def to_hash
    return { "name" => @name }
  end

  def to_s
    return @name
  end # def to_s
end

class Calmon::Models::Attribute
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :name, String
  property :value, String
end

class Calmon; class Models; class Test
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :name, String
  property :command, String
  property :interval, Integer

  def to_hash
    return {
      "name" => @name,
      "command" => @command,
      "interval" => @interval,
    }
  end

  def to_s
    return @name
  end # def to_s
end; end; end # class Calmon::Models::Tests
