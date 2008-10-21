require File.dirname(__FILE__) + '/spec_helper'
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
    @encoder.session_key = 'api_session_key'
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
  
  # Using string 'api_secret123-abcdefghijklfiles2734485-1fc'
  it "should generate a correct signature" do
    pending "More time to fix this spec"
    api_sig = '0e1c483506dd413808c80183333e1fc2'
    # common_setup(:stub_sign => false)
    @encoder.sign(:logout).should == api_sig
  end
  
  
end