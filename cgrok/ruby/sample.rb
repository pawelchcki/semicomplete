require "Grok"
require "pp"

patterns = {}
File.open("../grok-patterns").each do |line|
  line.chomp!
  next if line =~ /^#/ or line =~ /^ *$/
  name, pat = line.split(" ", 2)
  next if !name or !pat
  #x.add_pattern(name, pat)
  patterns[name] = pat
end

matches = [
  "%{SYSLOGBASE} Accepted %{NOTSPACE:method} for %{DATA:user} from %{IPORHOST:client} port %{INT:port}",
  "%{SYSLOGBASE} Did not receive identification string from %{IPORHOST:client}",
  "%{SYSLOGBASE} error: PAM: authentication error for %{DATA:user} from %{IPORHOST:client}",
  
  #"( *%{DATA:key}:%{NOTSPACE:value})+"
]

groks = matches.collect do |m|
  g = Grok.new
  patterns.each { |k,v|  g.add_pattern(k,v) }
  g.compile(m)
  g
end

$stdin.each do |line|
  groks.each do |grok|
    m = grok.match(line)
    if m
      puts
      puts m.subject
      pp m.captures
      break
    end
  end
end

