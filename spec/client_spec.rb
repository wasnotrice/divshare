require 'spec_helper'
require 'divshare/client'
include Divshare

module ClientSpecHelper
  include DivshareMockXML
 
  # Each setup must declare what @mock_response will return
  def common_setup()
    @api_key = 'api_key'
    @api_secret = 'api_secret'
    @api_session_key = '123-abcdefghijkl'
    @user_email = 'fake_user_email'
    @password = 'fake_password'
    @files = ['2734485-1fc', '2735059-62d']
    @api_url = URI.parse(Divshare::Client::API_URL)
  end
  
  def no_login_setup
    @mock_response = mock('response')
    Net::HTTP.should_receive(:post_form).once.and_return(@mock_response)       
    @client = Client.new(@api_key, @api_secret)
  end
  
  def login_setup
    @mock_response = mock('response')
    @mock_login_response = mock('login_response')
    Net::HTTP.should_receive(:post_form).twice.and_return(@mock_login_response, @mock_response)   
    @mock_login_response.should_receive(:body).and_return(successful_login_xml)
    @client = Client.new(@api_key, @api_secret)
    @client.login(@user_email, @password)
  end
end

describe "A new Divshare Client" do
  include ClientSpecHelper
  before :all do
    common_setup
  end
  
  before :each do
    @client = Client.new(@api_key, @api_secret)
  end

  it "should be created successfully" do
    @client.should be_instance_of(Divshare::Client)
  end
  
  it "should know the proper post url" do
    Divshare::Client::API_URL.should == "http://www.divshare.com/api/"
  end
  
  it "should raise Divshare::ConnectionError on timeout" do
    pending 'Timeout code implementation'
    lambda { @client.login('email', 'password') }.should raise_error(Divshare::ConnectionError)
  end
  
end

describe Divshare::Client, "making a request to the API" do
  # spec the request format. This should suffice for all requests.
  
end

describe "A Divshare Client getting one file" do
  include ClientSpecHelper
  before(:all) do
    common_setup
  end
  
  it "should return an array of one DivshareFile when requesting a file through get_files" do
    login_setup
    @mock_response.should_receive(:body).and_return(get_one_file_xml)
    @client.get_files('123456-abc').map {|f| f.class}.should == [DivshareFile]
  end
  
  it "should return a DivshareFile when requesting a file through get_file" do
    login_setup
    @mock_response.should_receive(:body).and_return(get_one_file_xml)
    @client.get_file('123456-abc').class.should == DivshareFile
  end
  
  it "should raise ArgumentError if an array is passed to get_file" do
    @client = Client.new(@api_key, @api_secret)
    lambda {@client.get_file(['123456-abc'])}.should raise_error(ArgumentError)
  end
end

describe "A Divshare Client getting two files" do
  include ClientSpecHelper
  before(:all) do
    common_setup
  end

  before :each do
    login_setup
    @mock_response.should_receive(:body).and_return(get_two_files_xml)
  end

  it "should return an array of two DivshareFiles" do
    @client.get_files(['123456-abc', '456789-def']).map {|f| f.class}.should == [DivshareFile, DivshareFile]
  end
end

describe "A Divshare Client getting user files" do
  include ClientSpecHelper
  before :all do
   common_setup
  end

  before :each do
    login_setup
    @mock_response.should_receive(:body).and_return(get_two_files_xml)
  end

  it "should return an array of files" do
    @client.get_user_files.map {|f| f.class }.should == [DivshareFile, DivshareFile]
  end
end

describe "A Divshare Client getting folder files" do
  include ClientSpecHelper
  before :all do
   common_setup
  end

  before :each do
    login_setup
    @mock_response.should_receive(:body).and_return(get_two_files_xml)
  end

  it "should return an array of files" do
    @client.get_folder_files('12345').map {|f| f.class }.should == [DivshareFile, DivshareFile]
  end
end

describe "A Divshare Client, creating an upload ticket" do
  include ClientSpecHelper
  before :all do
    common_setup
  end

  before :each do
    login_setup
    @mock_response.should_receive(:body).and_return(get_upload_ticket_xml)
  end
  
  it "should return an upload ticket" do
    @client.get_upload_ticket.should == '123-abcdefghijkl'
  end
end

describe "A Divshare Client, logging in" do
  include ClientSpecHelper
  before :all do
    common_setup
  end

  before :each do
    no_login_setup
    @mock_response.should_receive(:body).and_return(successful_login_xml)
  end

  it "should set api session key" do
    @client.session_key.should_not == @api_session_key
    @client.login(@user_email, @password)
    @client.session_key.should == @api_session_key
  end
end

describe "A DivshareClient, unsuccessfully logging in" do
  include ClientSpecHelper
  it "should raise Divshare::APIError" do
    common_setup
    no_login_setup
    @mock_response.should_receive(:body).and_return(error_xml("Couldn't log in"))
    lambda {@client.login(@user_email, @password)}.should raise_error(Divshare::APIError)
  end
end

describe "A Divshare Client, successfully logging out" do
  include ClientSpecHelper
  before :all do
    common_setup
  end

  before :each do
    login_setup
    @mock_response.should_receive(:body).and_return(successful_logout_xml)
  end

  it "should return true" do
    @client.logout.should be_true
  end

  it "should remove api session key" do
    @client.logout
    @client.session_key.should be_nil
  end
end

describe "A Divshare Client, unsuccessfully logging out" do
  include ClientSpecHelper
  
  it "should return false" do
    common_setup
    login_setup
    @mock_response.should_receive(:body).and_return(unsuccessful_logout_xml)
    lambda {@client.logout}.should raise_error(Divshare::APIError)
  end
end