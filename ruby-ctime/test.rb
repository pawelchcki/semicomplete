require "CTime"
require "date"

$str = "Sep 12 01:12:17 2009"
#$str = "Sep  6 09:11:21"
$fmt = "%b %e %H:%M:%S %Y"
$expect = "1252743137"

def clock(iterations)
  duration = 0
  start_time = Time.now
  1.upto(iterations) do
    date = yield
    #duration += (end_time - start_time)
    #if date.strftime("%s") != $expect
      #puts "strptime fail: #{date.strftime("%s")}"
    #end
  end
    end_time = Time.now
  duration = end_time - start_time
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

duration = clock($rounds) { datetime_strptime }
puts "datetime: #{duration} (#{$rounds / duration}/sec)"
duration = clock($rounds) { my_strptime }
puts "my: #{duration} (#{$rounds / duration}/sec)"
