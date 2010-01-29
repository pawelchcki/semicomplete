require 'dm-core'

class Calmon; class Models; class Entity
  include DataMapper::Resource

  property :name, String, :key => true
  property :type, Discriminator

  property :parent_id, Integer, :required => false
  has n, :children, :model => 'Entity', :child_key => [ :parent_id ]
  belongs_to :parent, :model => 'Entity', :child_key => [ :parent_id ]
  has n, :attributes
  #has n, :tests, :model => 'Entity', :child_key => [ :parent_id ]
  has n, :tests, :through => Resource

  def to_hash
    return { "name" => @name }
  end
end; end; end # class Calmon::Models::Entitty

class Calmon::Models::Host < Calmon::Models::Entity
end # class Calmon::Models::Host

class Calmon::Models::Service < Calmon::Models::Entity
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
end; end; end # class Calmon::Models::Tests
