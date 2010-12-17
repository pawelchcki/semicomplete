require 'rubygems'
require 'celerity'
require 'rspec'

BROWSER = Celerity::Browser.new
TIMEOUT = 20

class ContentNotFoundException < Exception;
  def initialize(message = nil, duration = TIMEOUT)
    message ||= "Content not found in #{duration} seconds"
    super(message)
  end
end;

# this is a simple utility function I use to find content on a page
# even if it might not appear straight away
def check_for_presence_of(content)
  begin
      timeout(TIMEOUT) do
        sleep 1 until BROWSER.html.include? content
      end
    rescue Timeout::Error
      raise ContentNotFoundException
    end
end

Given /^I'm on the homepage$/ do
  BROWSER.goto("http://www.freeagentcentral.com")
end

When /^I click the login button$/ do
  check_for_presence_of "Log In"
  BROWSER.div(:id, "login_box").visible?.should == false  
  BROWSER.link(:id, "login_link").click
end

Then /^I should see the login box$/ do
  BROWSER.div(:id, "login_box").visible?.should == true
end

