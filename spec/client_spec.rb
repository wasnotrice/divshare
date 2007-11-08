require File.dirname(__FILE__) + '/spec_helper'
require 'divshare/client'

describe "A Divshare Client object" do
  before(:each) do
    @client = Divshare::Client.new('username', 'password')
    # Intercept calls to #login and set @api_session_key manually
    @client.stub!(:login).and_return("123-abcdefghijkl")
    @client.instance_variable_set(:@api_session_key, @client.login)
    @file_id = '2192839-522'
  end
  it "should generate a good post string" do
    @client.post_args("get_files", {"files" => @file_id}).should == ""
  end
  
  it "should generate a correct signature" do
    @client.sign("get_files", {"files" => @file_id}).should == "dc7ae6c457c51754885c4f7154cedf1c"
  end
  
  it "should generate a string to sign that matches the one from the php library" do
    @client.string_to_sign("files" => @file_id).should == "8e67d3475573206-1e74e823c993files2092839-522"
  end
end

