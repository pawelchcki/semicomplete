#!/usr/bin/env ruby
require "socket"
require "etc"

if ARGV.length < 4
  puts "Usage: $0 [host]:port user group command [arg1 ...]"
  exit 1
end

address = ARGV.shift
user = ARGV.shift
group = ARGV.shift

# Setup the socket
addrdata = address.split(":")
if addrdata.length == 1
  host = "0.0.0.0"
  port = addrdata[0]
else
  host, port = addrdata
end
include Socket::Constants
socket = Socket.new( AF_INET, SOCK_STREAM, 0 )
sockaddr = Socket.pack_sockaddr_in( port, host )
socket.bind( sockaddr )

# setuid
pw = Etc.getpwnam(user)
gr = Etc.getgrnam(group)

puts "setgid: #{gr.gid} (#{group})"
Process::Sys.setgid(gr.gid)
puts "setuid: #{pw.uid} (#{user})"
Process::Sys.setuid(pw.uid)

ENV["BINDFD"] = socket.fileno.to_s
ENV["BINDPORT"] = port
ENV["LD_PRELOAD"] = "/home/jls/projects/liboverride/bindandswitch.so"

puts "Exec: #{ARGV.inspect}"

exec *ARGV
