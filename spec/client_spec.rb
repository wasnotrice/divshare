require File.dirname(__FILE__) + '/spec_helper'
require 'divshare/client'

module DivshareClientSpecHelper
  def new_client
    Divshare::Client.new('api_key', 'api_secret')
  end

  def new_client_with_email_and_password
    Divshare::Client.new('api_key', 'api_secret', 'email', 'password')
  end
  
  def basic_post_args(to_merge={})
    {'api_key' => 'api_key', "api_sig" => @api_sig, "api_session_key" => @api_session_key}.merge(to_merge)
  end
  
  # From http://www.divshare.com/integrate/api
  def get_one_file_xml
    <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <response status="1">
        <files>
            <file>
                <file_id>123456-abc</file_id>
                <file_name>My Resume.doc</file_name>
                <file_description>Resume (Draft 3)</file_description>
                <file_size>0.4 MB</file_size>
                <downloads>4</downloads>
                <last_downloaded_at>1192417863</last_downloaded_at>
                <uploaded_at>1192454938</uploaded_at>
                <folder_title>Job Applications</folder_title>
                <folder_id>12345</folder_id>
            </file>
        </files>
    </response>
    EOS
  end
  
  def get_two_files_xml
    <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <response status="1">
        <files>
            <file>
                <file_id>123456-abc</file_id>
                <file_name>My Resume.doc</file_name>
                <file_description>Resume (Draft 3)</file_description>
                <file_size>0.4 MB</file_size>
                <downloads>4</downloads>
                <last_downloaded_at>1192417863</last_downloaded_at>
                <uploaded_at>1192454938</uploaded_at>
                <folder_title>Job Applications</folder_title>
                <folder_id>12345</folder_id>
            </file>
            <file>
                <file_id>123456-abc</file_id>
                <file_name>My Resume.doc</file_name>
                <file_description>Resume (Draft 3)</file_description>
                <file_size>0.4 MB</file_size>
                <downloads>4</downloads>
                <last_downloaded_at>1192417863</last_downloaded_at>
                <uploaded_at>1192454938</uploaded_at>
                <folder_title>Job Applications</folder_title>
                <folder_id>12345</folder_id>
            </file>
        </files>
    </response>
    EOS
  end
  
  def login_xml
    <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <response status="1">
        <api_session_key>123-abcdefghijkl</api_session_key>
    </response>
    EOS
  end
  
end

describe "A new Divshare Client" do
  include DivshareClientSpecHelper

  it "should be created with api key and secret only" do
    new_client.should be_instance_of(Divshare::Client)
  end
  
  it "should be created with api key, api_secret, email, and password" do
    new_client_with_email_and_password.should be_instance_of(Divshare::Client)
  end
  
  it "should assign api key, api_secret, email, and password correctly" do
    client = new_client_with_email_and_password
    [client.api_key, client.api_secret, client.email, client.password].should == ['api_key', 'api_secret', 'email', 'password']
  end
  
  it "should know the proper post url" do
    new_client.post_url.should == "http://www.divshare.com/api/"
  end 
end

describe "A Divshare Client getting one file" do
  include DivshareClientSpecHelper
  before(:each) do
    @client = new_client
    # Intercept calls to #login and set @api_session_key manually
    @api_session_key = '123-abcdefghijkl'
    @client.stub!(:login).and_return(@api_session_key)
    @client.instance_variable_set(:@api_session_key, @client.login)
    @file_id = '2192839-522'
    @api_sig = '0070db55f389a6fe16ec150777363d4d'
    @mock_response = mock('response')
    Net::HTTP.stub!(:post_form).and_return(@mock_response)
  end

  # If it generates a PostArgs object, it's doing the right thing
  it "should generate arguments for post" do
    @mock_response.should_receive(:body).and_return(get_one_file_xml)
    PostArgs.should_receive(:new).with(@client,:get_files,{'files' => @file_id})
    @client.files(@file_id)
  end
  
  # Working from 'api_secret123-abcdefghijklfiles2192839-522'
  it "should generate a correct signature" do
    @client.sign("get_files", {"files" => @file_id}).should == @api_sig
  end
  
  it "should return an array of one Divshare::File when requesting a file" do
    @mock_response.should_receive(:body).and_return(get_one_file_xml)
    @client.files('bogus_file_id').map {|f| f.class}.should == [Divshare::File]
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

  it "should return an array of two Divshare::Files when requesting two files" do
    mock_response = mock('response')
    Net::HTTP.stub!(:post_form).and_return(mock_response)
    mock_response.should_receive(:body).and_return(get_two_files_xml)
    @client.files(['bogus_file_id', 'other']).map {|f| f.class}.should == [Divshare::File, Divshare::File]
  end
end

describe "A Divshare Client, not logged in" do
  include DivshareClientSpecHelper
  before(:each) do
    @client = new_client_with_email_and_password
    @file_id = '2192839-522'
    @api_sig = '0070db55f389a6fe16ec150777363d4d'
  end
  it "should generate proper arguments for login" do
    mock_response = mock('response')
    Net::HTTP.should_receive(:post_form).with(URI.parse(@client.post_url), {"method" => "login", "user_email" => 'email', 'user_password' => 'password', 'api_key' => 'api_key'}).and_return(mock_response)
    mock_response.should_receive(:body).and_return(login_xml)
    @client.login
  end
  
end

