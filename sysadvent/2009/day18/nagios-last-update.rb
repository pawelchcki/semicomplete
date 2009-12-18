#!/usr/bin/env ruby
# Author: Jordan Sissel
# License: BSD
#
# Usage:
# nagios-last-update.rb -- <nagioshost> <maxage>
#   nagioshost should be the web server in front of nagios
#   maxage is a value in seconds.
#

require 'rubygems'
require 'mechanize'
require 'date'
require 'test/unit'

class NagiosHealthTest < Test::Unit::TestCase
  def test_nagios_last_command_check_age
    nagioshost = ARGV[0]
    maxage = ARGV[1].to_f

    mech = WWW::Mechanize.new
    page = mech.get("http://#{nagioshost}/nagios/cgi-bin/extinfo.cgi?type=0")

    # find the row like this:
    # <TR><TD CLASS='dataVar'>Last External Command Check:</TD>
    #     <TD CLASS='dataVal'>12-18-2009 03:47:22</TD></TR>
    # And get that 2nd column.
    rowtext = "Last External Command Check:"
    xpath = "//tr[contains(td/text(), '#{rowtext}')]/td[@class='dataVal']/text()"
    last_update_str = page.search(xpath).to_s

    now = Time.now
    last_update_time = Time.parse(DateTime.strptime(last_update_str,
                                                    "%m-%d-%Y %H:%M:%S").to_s)

    # Since the time reported by nagios doesn't include a zone, and parsing it
    # defaults to GMT, add local timezone offset.
    last_update_time -= now.gmt_offset

    # Require last check run to be less than 15 minutes ago.
    age = now - last_update_time
    assert(age < maxage, 
           "Time of last Nagios check is older than #{maxage} seconds.")
  end # def test_nagios_last_command_check_age
end # class NagiosHealthTest
