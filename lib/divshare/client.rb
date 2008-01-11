require 'rubygems'
require 'cgi'
require 'net/http'
require 'hpricot'
require 'digest/md5'
require 'divshare/errors'
require 'divshare/divshare_file'
require 'divshare/post_args'
require 'divshare/user'

module Divshare
  # This is the main class for interacting with the Divshare API. Use it like this:
  #
  #   client = Divshare::Client.new(api_key, api_secret)
  #   client.login(email, password)
  #   files = client.get_files ['abcdefg-123', 'abcdefg-456']
  #   upload_ticket = client.get_upload_ticket
  #   client.logout
  #
  class Client
    SUCCESS = '1'
    FAILURE = '0'
  
    attr_reader :api_key, :api_secret, :post_url, :api_session_key, :email, :password
    
    # Creates a Divshare::Client. The <tt>api_key</tt> and <tt>api_secret</tt>
    # are required, but <tt>email</tt> and <tt>password</tt> are optional. If
    # you omit <tt>email</tt> and <tt>password</tt> here, you must send them
    # with link:login when you call it.
    def initialize(api_key, api_secret, email=nil, password=nil)
      @api_key, @api_secret, @email, @password = api_key, api_secret, email, password
      @api_session_key = nil
      @post_url = "http://www.divshare.com/api/"
    end

    # file_ids should be an array of file ids
    # def get_files(file_ids)
    #   file_ids = [file_ids] unless file_ids.respond_to?(:join)
    #   response = send_method(:get_files, 'files' => file_ids.join(','))
    #   files_from response
    # end

    # This method replaces the real get_files until the API is cleared up and
    # working properly. Limitation: it can only retrieve files owned by the
    # logged-in user.
    def get_files(file_ids)
      file_ids = [file_ids] unless file_ids.is_a? Array
      files = get_user_files
      puts file_ids.class
      files.delete_if {|f| file_ids.include?(f.file_id) == false}
    end
    
    # A convenience method for finding only one file. Returns a single
    # DivshareFile instead of an array.
    def get_file(file_id)
      raise ArgumentError, "Only one file id allowed for this method" if file_id.is_a?(Array)
      get_files(file_id).first
    end

    # Returns an array of Divshare::DivshareFile objects belonging to the logged-in user. Use <tt>limit</tt> and
    # <tt>offset</tt> to narrow things down.
    def get_user_files(limit=nil, offset=nil)
      args = {}
      args['limit'] = limit unless limit.nil?
      args['offset'] = offset unless offset.nil?
      response = send_method(:get_user_files, args)
      files_from response
    end
    
    # Returns an array of Divshare::DivshareFile objects in the specified folder. Use <tt>limit</tt> and
    # <tt>offset</tt> to narrow things down. 
    def get_folder_files(folder_id, limit=nil, offset=nil)
      args = {}
      args['limit'] = limit unless limit.nil?
      args['offset'] = offset unless offset.nil?
      args['folder_id'] = folder_id
      response = send_method(:get_folder_files, args)
      files_from response
    end

    # Returns information about the logged-in user
    def get_user_info
      response = send_method :get_user_info
      user_from response
    end
    
    # Returns an upload ticket string for use in uploading files. See
    # http://www.divshare.com/integrate/api#uploading for more information on
    # how to use the upload ticket once you've got it.
    def get_upload_ticket
      response = send_method :get_upload_ticket
      upload_ticket_from response
    end

    # Login to the Divshare service. Raises Divshare::APIError if login is
    # unsuccessful.
    def login(email=nil, password=nil)
      logout if @api_session_key
      email ||= @email
      password ||= @password
      response = send_method(:login, {'user_email' => email, 'user_password' => password})
      if response.at(:api_session_key)
        @api_session_key = response.at(:api_session_key).inner_html
      else
        raise Divshare::APIError, "Couldn't log in. Received: \n" + response.to_s
      end
    end

    # Returns true if logout is successful. Raises Divshare::APIError if logout is
    # unsuccessful.
    def logout
      response = send_method(:logout)
      if response.at(:logged_out) && (%w(true 1).include? response.at(:logged_out).inner_html)
        @api_session_key = nil
      else
        raise Divshare::APIError, "Couldn't log out. Received: \n" + response.to_s
      end
      true
    end

    # Generates the required MD5 signature as described in
    # http://www.divshare.com/integrate/api#sig
    def sign(method, args)
      Digest::MD5.hexdigest(string_to_sign(args))
    end

    private
    def files_from(xml)
      xml = xml/:file
      xml = [xml] unless xml.respond_to?(:each)    
      files = xml.collect { |f| DivshareFile.new f }
    end
    
    def user_from(xml)
      xml = xml.at(:user_info)
      Divshare::User.new(xml)
    end
    
    def upload_ticket_from(xml)
      xml = xml.at(:upload_ticket).inner_html
    end
    
    # Since login and logout aren't easily re-nameable to use method missing
    def send_method(method_id, *params)
      response = http_post(method_id, *params)
      xml = Hpricot(response).at(:response)
      if xml[:status] == FAILURE
        errors = (xml/:error).collect {|e| e.inner_html}
        raise Divshare::APIError, errors.join("\n")
      end
      xml
    end      
    
    def post_args(method, args)
      PostArgs.new(self, method, args)
    end
    
    def http_post(method, args={})
      url = URI.parse(@post_url)
      tries = 3
      response = ""
      begin
        response = Net::HTTP.post_form(url, post_args(method, args)).body
      rescue
        tries -= 1
          puts "Tries == '#{tries}'"
        if tries > 0
          retry
        else
          raise Divshare::ConnectionError, "Couldn't connect for '#{method}' using #{post_args(method, args)}"
        end
      end
      response
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
  end
end