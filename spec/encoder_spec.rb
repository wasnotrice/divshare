require 'spec_helper'
require 'divshare/client'
require 'divshare/encoder'
include Divshare

module EncoderSpecHelper
  def basic_args(to_merge={})
    {'api_key' => 'api_key', "api_session_key" => 'api_session_key'}.merge(to_merge)
  end
  
  def login_args(to_merge={})
    args = basic_args(to_merge).reject { |k,v| %w(api_session_key).include? k }
    args.merge({'method' => 'login'})
  end
  
  def logout_args(to_merge={})
    basic_args.merge({'method' => 'logout'})
  end
  
  def excluding_sig(hash)
    return hash.reject {|k,v| k == 'api_sig'}
  end
  
  def common_setup
    @key = 'api_key'
    @secret = 'api_secret'
    @encoder = Encoder.new(@key, @secret)
    # @client = mock('client')
    # @client.should_receive(:api_key).and_return('api_key')
    @login = {'user_email' => 'email', 'user_password' => 'password'}
    @login_as_symbols = {:user_email => :email, :user_password => :password}
  end
end

describe "An Encoder" do
  include EncoderSpecHelper
  
  before(:each) do
    common_setup
  end
  
  it "should record key" do
    @encoder.key.should == @key
  end
  
  it "should record secret" do
    @encoder.secret.should == @secret
  end
  
  it "should generate appropriate arguments for login" do
    @encoder.encode(:login, @login).should == login_args(@login)
  end
  
  it "should stringify keys and values for login" do
    @encoder.encode(:login, @login_as_symbols).should == login_args(@login)
  end
  
end

describe "An Encoder, after client login" do
  include EncoderSpecHelper
  
  before(:each) do
    common_setup
    # Simulates login
    @session_key = 'api_session_key'
    @encoder.session_key = @session_key
  end
  
  it "should generate appropriate arguments for logout" do
    result = @encoder.encode(:logout,{})
    excluding_sig(result).should == basic_args({'method' => 'logout'})
  end
  
  it "should work without additional hash of arguments" do
    result = @encoder.encode(:logout)
    excluding_sig(result).should == basic_args({'method' => 'logout'})    
  end
  
  it "should convert symbol keys and values to strings" do
    args_as_symbols = {:file_id => :abc123}
    args_as_strings = {'file_id' => 'abc123'}
    result = @encoder.encode(:get_files, args_as_symbols)
    expected = basic_args.merge(args_as_strings)
    expected.merge!("method" => "get_files")
    excluding_sig(result).should == expected
  end
  
  it "should generate proper arguments for post request" do
    method = :get_user_files
    args = {:offset => 3, :limit => 10}
    # api_sig is the md5 digest of 'api_secretapi_session_keylimit10offset3'
    @encoder.encode(method, args).should == {'method' => 'get_user_files',
                                             'api_sig' => '1bfa96cc8e92807f96f5694d641d810b',
                                             'offset' => '3',
                                             'limit' => '10',
                                             'api_key' => @key,
                                             'api_session_key' => @session_key}
  end  
end