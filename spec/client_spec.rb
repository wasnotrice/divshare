require File.dirname(__FILE__) + '/spec_helper'
require 'divshare/client'

module DivshareClientSpecHelper
  def new_client
    Divshare::Client.new('api_key', 'api_secret')
  end

  def new_client_with_username_and_password
    Divshare::Client.new('api_key', 'api_secret', 'username', 'password')
  end
end

describe "A new Divshare Client" do
  include DivshareClientSpecHelper

  it "should be created with api key and secret only" do
    new_client.should be_instance_of(Divshare::Client)
  end
  
  it "should be created with api key, api_secret, username, and password" do
    new_client_with_username_and_password.should be_instance_of(Divshare::Client)
  end
  
  it "should assign api key, api_secret, username, and password correctly" do
    client = new_client_with_username_and_password
    [client.api_key, client.api_secret, client.username, client.password].should == ['api_key', 'api_secret', 'username', 'password']
  end
  
  it "should know the proper post url" do
    new_client.post_url.should == "http://www.divshare.com/api/"
  end 
end

describe "A Divshare Client" do
  include DivshareClientSpecHelper
  before(:each) do
    @client = new_client
    # Intercept calls to #login and set @api_session_key manually
    @api_session_key = '123-abcdefghijkl'
    @client.stub!(:login).and_return(@api_session_key)
    @client.instance_variable_set(:@api_session_key, @client.login)
    @file_id = '2192839-522'
    @api_sig = '0070db55f389a6fe16ec150777363d4d'
  end

  it "should generate proper arguments for post" do
    @client.post_args("get_files", {"files" => @file_id}).should == {"method" => "get_files", "files" => @file_id, 'api_key' => 'api_key', "api_sig" => @api_sig, "api_session_key" => @api_session_key}
  end
  
  # Working from 'api_secret123-abcdefghijklfiles2192839-522'
  it "should generate a correct signature" do
    @client.sign("get_files", {"files" => @file_id}).should == @api_sig
  end
end

