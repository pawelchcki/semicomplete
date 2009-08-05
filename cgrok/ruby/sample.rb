require "Grok"
require "pp"

x = Grok.new

File.open("../grok-patterns").each do |line|
  line.chomp!
  next if line =~ /^#/ or line =~ /^ *$/
  name, pat = line.split(" ", 2)
  next if !name or !pat
  x.add_pattern(name, pat)
end

#x.compile("%{SYSLOGBASE:test}")
x.compile("%{SYSLOGBASE} Accepted %{NOTSPACE:method} for %{DATA:user} from %{IPORHOST:client} port %{INT:port}")

$stdin.each do |line|
  begin
    pp x.match(line)
  rescue ArgumentError
  end
end

