require "CTime"
require "date"

ENV["TZ"] = "UTC"
$str = "Sep 12 01:12:17 2009"
#$str = "Sep  6 09:11:21"
$fmt = "%b %e %H:%M:%S %Y"
$expect = "1252717937"

def clock(iterations)
  duration = 0
  1.upto(iterations) do
    start_time = Time.now
    date = yield
    end_time = Time.now
    duration += (end_time - start_time)
    if date.strftime("%s") != $expect
      puts "strptime fail: #{date.strftime("%s")}"
    end
  end
  return duration
end

def datetime_strptime
  x = DateTime.strptime($str, $fmt)
  return x
end

def my_strptime
  x = Time.strptime($str, $fmt)
  return x
end

$rounds = 10000

puts "Iterations: #{$rounds}"
duration = clock($rounds) { datetime_strptime }
puts "datetime: #{duration} (#{$rounds / duration}/sec)"
duration = clock($rounds) { my_strptime }
puts "my_strptime: #{duration} (#{$rounds / duration}/sec)"
