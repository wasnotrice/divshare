require File.dirname(__FILE__) + '/spec_helper'
require 'divshare/client'
include Divshare

module ClientSpecHelper
  include DivshareMockXML
  def new_client
    Client.new('api_key', 'api_secret')
  end
  
  def login(client, api_session_key='123-abcdefghijkl')
    client.stub!(:login).and_return(api_session_key)
    client.instance_variable_set(:@api_session_key, client.login)
    api_session_key
  end
  
  # Each setup must declare what @mock_response will return
  def common_setup(opts={})
    options = {:login => true, :stub_sign => true}.merge(opts)
    @client = new_client
    @api_session_key = login(@client) if options[:login]
    @files = ['2734485-1fc', '2735059-62d']
    if opts[:stub_sign]
      @api_sig = 'api_sig'
      @client.stub!(:sign).and_return(@api_sig)
    end
    @mock_response = mock('response')
    Net::HTTP.stub!(:post_form).and_return(@mock_response)
  end
  
  def basic_post_args(to_merge={})
    {'api_key' => 'api_key', "api_sig" => @api_sig, "api_session_key" => @api_session_key}.merge(to_merge)
  end
end

describe "A new Divshare Client" do
  include ClientSpecHelper
  before :each do
    common_setup
  end

  it "should be created with api key and secret only" do
    @client.should be_instance_of(Divshare::Client)
  end
  
  it "should assign api key correctly" do
    @client.api_key.should == 'api_key'
  end
  
  it "should assign api secret correctly" do
    @client.api_secret.should == 'api_secret'
  end
  
  it "should know the proper post url" do
    Divshare::Client::API_URL.should == "http://www.divshare.com/api/"
  end
  
  it "should raise Divshare::ConnectionError on timeout" do
    pending "Rewrite of spec to actually test failure"
    # Net::HTTP.should_receive(:post_form).once.and_raise
    Net::HTTP.stub!(:post_form).and_raise(Net::HTTPServerError)
    lambda { @client.login('email', 'password') }.should raise_error(Divshare::ConnectionError)
  end
  
end

describe "A Divshare Client getting one file" do
  include ClientSpecHelper
  before(:each) do
    common_setup
  end

  # If it generates a PostArgs object, it's doing the right thing
  it "should generate arguments for post" do
    pending("Fix to API that allows correct get_files method")
    @mock_response.should_receive(:body).and_return(get_one_file_xml)
    PostArgs.should_receive(:new).with(@client,:get_files,{'files' => @files.first})
    @client.get_files(@files.first)
  end
  
  it "should return an array of one DivshareFile when requesting a file through get_files" do
    @mock_response.should_receive(:body).and_return(get_one_file_xml)
    @client.get_files('123456-abc').map {|f| f.class}.should == [DivshareFile]
  end
  
  it "should return a DivshareFile when requesting a file through get_file" do
    @mock_response.should_receive(:body).and_return(get_one_file_xml)
    @client.get_file('123456-abc').class.should == DivshareFile
  end
  
  it "should raise ArgumentError if an array is passed to get_file" do
    lambda {@client.get_file(['123456-abc'])}.should raise_error(ArgumentError)
  end
end

describe "A Divshare Client getting two files" do
  include ClientSpecHelper
  before(:each) do
    common_setup
  end

  it "should return an array of two DivshareFiles" do
    mock_response = mock('response')
    Net::HTTP.stub!(:post_form).and_return(mock_response)
    mock_response.should_receive(:body).and_return(get_two_files_xml)
    @client.get_files(['123456-abc', '456789-def']).map {|f| f.class}.should == [DivshareFile, DivshareFile]
  end
end

describe "A Divshare Client getting user files" do
  include ClientSpecHelper
  before(:each) do
   common_setup
   @mock_response.should_receive(:body).and_return(get_two_files_xml)
  end

  it "should return an array of files" do
    @client.get_user_files.map {|f| f.class }.should == [DivshareFile, DivshareFile]
  end
  
  # If it generates a PostArgs object, it's doing the right thing
  it "should generate arguments for post" do
    PostArgs.should_receive(:new).with(@client,:get_user_files, {})
    @client.get_user_files
  end
  
  it "should generate arguments for post with limit and offset" do
    PostArgs.should_receive(:new).with(@client, :get_user_files, {"limit" => 5, "offset" => 2})
    @client.get_user_files(5, 2)
  end
  
end

describe "A Divshare Client getting folder files" do
  include ClientSpecHelper
  before(:each) do
   common_setup
   @mock_response.should_receive(:body).and_return(get_two_files_xml)
  end

  it "should return an array of files" do
    @client.get_folder_files('12345').map {|f| f.class }.should == [DivshareFile, DivshareFile]
  end
  
  # If it generates a PostArgs object, it's doing the right thing
  it "should generate arguments for post" do
    PostArgs.should_receive(:new).with(@client,:get_folder_files, {'folder_id' => '12345'})
    @client.get_folder_files('12345')
  end

  it "should generate arguments for post with limit and offset" do
    PostArgs.should_receive(:new).with(@client, :get_folder_files, {'folder_id' => '12345', "limit" => 5, "offset" => 2})
    @client.get_folder_files('12345', 5, 2)
  end
  

end

describe "A Divshare Client, creating an upload ticket" do
  include ClientSpecHelper
  before(:each) do
    common_setup
    @mock_response.should_receive(:body).and_return(get_upload_ticket_xml)
  end
  it "should return an upload ticket" do
    @client.get_upload_ticket.should == '123-abcdefghijkl'
  end
end

describe "A Divshare Client, logging in" do
  include ClientSpecHelper
  before(:each) do
    common_setup(:login => false)
    @api_session_key = login(new_client)
    @mock_response.should_receive(:body).and_return(successful_login_xml)
  end

  it "should login" do
    @client.login.should == @api_session_key
  end
  
  it "should set api session key" do
    @client.api_session_key.should be_nil
    @client.login
    @client.api_session_key.should == @api_session_key
  end
end

describe "A DivshareClient, unsuccessfully logging in" do
  include ClientSpecHelper
  it "should raise Divshare::APIError" do
    common_setup(:login => false)
    @mock_response.should_receive(:body).and_return(error_xml("Couldn't log in"))
    lambda {@client.login}.should raise_error(Divshare::APIError)
  end
end

describe "A Divshare Client, logging out" do
  include ClientSpecHelper
  before(:each) do
    common_setup
    @mock_response.should_receive(:body).and_return(successful_logout_xml)
  end

  it "should logout" do
    @client.logout.should be_true
  end
  
  it "should remove api session key on logout" do
    @client.logout
    @client.api_session_key.should be_nil
  end
end