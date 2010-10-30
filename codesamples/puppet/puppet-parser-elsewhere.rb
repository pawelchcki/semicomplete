#!/usr/bin/env ruby
#

require "rubygems"
require "puppet" # gem puppet
require "ap" # gem awesome_print

Puppet::Type.newtype(:input) do
  newproperty(:name) do
    desc "Input URL"
  end # property :name

  newproperty(:tags) do
    desc "Tags for an input"
  end # property 'tags'
end # type 'input'

# This is where we put the puppet manifest code. You could just use a file
# here, but I'm inlining it for easy reading.
Puppet[:code] = <<EOF
input {
  [ "/var/log/messages", "/var/log/auth.log" ]:
    tags => ["linux-syslog"];
  [ "/var/log/apache2/access.log" ]:
    tags => ["apache-access"];
}
EOF

# Now compile a catalog from our code.
node = Puppet::Node.find("default")
catalog = Puppet::Resource::Catalog.find("default", :use_node => node)

# Each vertex is a resource.
catalog.vertices.each do |resource|
  next if ["Class", "Stage"].include?(resource.type )
  puts "Found resource '#{resource.to_s}' with tags: #{resource[:tags].inspect}"
  
end
