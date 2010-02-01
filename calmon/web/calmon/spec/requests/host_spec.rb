require File.join(File.dirname(__FILE__), '..', 'spec_helper.rb')

describe "/host" do
  before(:each) do
    @response = request("/host")
  end
end