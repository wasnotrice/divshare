require 'rubygems'
require 'cgi'
require 'net/http'
require 'hpricot'
require 'digest/md5'
require 'divshare/file'

module Divshare
  class Client
    SUCCESS = '1'
    FAILURE = '0'
  
    attr_reader :api_key, :api_secret, :post_url, :api_session_key, :username, :password

    def initialize(api_key, api_secret, username=nil, password=nil)
      @api_key, @api_secret, @username, @password = api_key, api_secret, username, password
      @post_url = "http://www.divshare.com/api/"
    end

    # file_ids should be an array of file ids
    def get_files(file_ids)
      file_ids = [file_ids] unless file_ids.respond_to?(:join)
      args = {'files' => file_ids.join(',')}
      files_from(call_method('get_files', args).at(:response)/:file)
    end

    def files_from(xml)
      xml = [xml] unless xml.respond_to?(:each)    
      files = xml.collect { |f| Divshare::File.new f }
    end

    def get_user_files(limit=nil, offset=nil)
      args = {}
      args['limit'] = limit unless limit.nil?
      args['offset'] = offset unless offset.nil?
      files_from(call_method('get_user_files', args).at(:response)/:file)
    end

    def call_method(method, args)
      response = Hpricot(http_post(method, args))
      puts "Error: " + response.at('error').inner_html if response.at('response')[:status] == "0"
      response
    end

    def login(username=nil, password=nil)
      username ||= @username
      password ||= @password
      xml = call_method('login', {:username => username, :password => password})
      @api_session_key = xml.at("response api_session_key").inner_html
    end

    def logout
      response = call_method('logout', {}).at(:response)
      response.at(:logged_out) ? response.at(:logged_out).inner_html == 'true' : false
    end

    # From http://www.divshare.com/integrate/api
    #
    # * Your secret key is 123-secret. 
    # * Your session key is 456-session. 
    # * You are using the get_user_files method, and you're sending the
    #   parameters limit=5 and offset=10.
    #
    # The string used to create your signature will be:
    # 123-secret456-sessionlimit5offset10. Note that the parameters must be in
    # alphabetical order, so limit always comes before offset. Each parameter
    # should be paired with its value as shown.
    def string_to_sign(args)
      args_for_string = args.dup.delete_if {|k,v| %w(api_key method api_sig api_session_key).include?(k) }
      "#{@api_secret}#{@api_session_key}#{args_for_string.to_a.sort.flatten.join}"
    end

    def sign(method, args)
      Digest::MD5.hexdigest(string_to_sign(args))
    end

    def post_args(method, args)
      args.merge!({'method' => method, 'api_key' => @api_key})
      if @api_session_key
        api_sig = sign(method, args)
        args.merge!({'api_session_key' => @api_session_key, 'api_sig' => api_sig})
      end
      args
     end

    def http_post(method, args)
      url = URI.parse(@post_url)
      Net::HTTP.post_form(url, post_args(method, args)).body
    end
  end
end