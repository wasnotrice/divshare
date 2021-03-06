require 'cgi'
require 'net/http'
require 'hpricot'
require 'digest/md5'
require 'divshare/divshare_file'
require 'divshare/encoder'
require 'divshare/errors'
require 'divshare/multipart'
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
    
    API_URL = 'http://www.divshare.com/api/'
    UPLOAD_URL = 'http://upload.divshare.com'
    UPLOAD_PATH = '/api/upload'
    
    SUCCESS = '1'
    FAILURE = '0'
  
    attr_accessor :debug # If true, extended debugging information is printed

    def initialize(key, secret)
      @encoder = Encoder.new(key, secret)
      # @debug = true
    end
    
    def key
      @encoder.key
    end
    
    def secret
      @encoder.secret
    end

    def session_key
      @encoder.session_key
    end
    
    def login(email, password)
      logout if @encoder.session_key
      response = send_method(:login, {'user_email' => email, 'user_password' => password})
      @encoder.session_key = response.at(:api_session_key).inner_html
    end

    # Returns true if logout is successful. 
    def logout
      response = send_method(:logout)
      debug response.to_html
      if response[:status] == SUCCESS
        @encoder.session_key = nil
        true
      else
        false
      end
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
      debug "DivShare.get_files(): #{file_ids.class}"
      files = get_user_files
      files.delete_if {|f| file_ids.include?(f.file_id) == false}
    end
    
    # A convenience method for finding only one file. Returns a single
    # DivshareFile instead of an array.
    def get_file(file_id)
      raise ArgumentError, "Only one file id allowed for this method" if file_id.is_a?(Array)
      get_files(file_id).first
    end

    # Returns an array of Divshare::DivshareFile objects belonging to the
    # logged-in user. Use <tt>limit</tt> and <tt>offset</tt> to narrow things
    # down.
    def get_user_files(limit=nil, offset=nil)
      args = {}
      args['limit'] = limit unless limit.nil?
      args['offset'] = offset unless offset.nil?
      response = send_method(:get_user_files, args)
      files_from response
    end
    
    # Returns an array of Divshare::DivshareFile objects in the specified
    # folder. Use <tt>limit</tt> and <tt>offset</tt> to narrow things down. 
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
      response = send_method(:get_user_info)
      user_from(response)
    end
    
    # Returns an upload ticket string for use in uploading files. See
    # http://www.divshare.com/integrate/api#uploading for more information on
    # how to use the upload ticket once you've got it.
    def get_upload_ticket
      send_method(:get_upload_ticket).at(:upload_ticket).inner_html
    end

    # Uploads a file or files to the user's DivShare account, and returns the
    # file id(s). 
    #
    # The DivShare API is written for use with actual HTML forms, so the API
    # method requires a 'response_url', and makes a GET request to that url,
    # sending the file id(s) as query parameters.
    #
    # Here, we're simulating the form, so we parse DivShare's GET request and
    # simply return the file id(s). In this case, response_url is just a 
    # filler so that the server doesn't complain.
    def upload(ticket, file_path, response_url='www.divshare.com/upload_result')      
      location = nil
      File.open(file_path, 'r') { |file|
        uri = URI.parse(UPLOAD_URL)
        http = Net::HTTP.new(uri.host, uri.port)
        # API methods can be SLOW. Timeout interval should be long.
        http.read_timeout = 15*60
        request = Net::HTTP::Post.new(UPLOAD_PATH)
        fields = Hash.new
        fields['upload_ticket'] = ticket
        # API doesn't allow blank response_url. This is just filler.
        fields['response_url'] = response_url

        fields['file1'] = file
        request.multipart_params = fields
        # Until DivShare supports direct upload API, we deal with its response location field
        location = http.request(request)['location']
      }
      
      # if error, throw, otherwise return file ID for caller to do whatever they like
      resp = {}
      location.split('?')[1].split('&').each { |param| 
        k, v = param.split('=', 2)  # some params could contain two '=' for some reason
        resp[k]=CGI.unescape(v)
      }
      if resp['error']
        raise Divshare::APIError, resp['description']
      else
        resp['file1']   # return the file ID
      end
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
    
    def send_method(method_id, *params)
      response = http_post(method_id, *params)
      xml = Hpricot(response).at(:response)
      if xml[:status] == FAILURE
        errors = (xml/:error).collect {|e| e.inner_html}
        raise Divshare::APIError, errors.join("\n")
      end
      xml
    end

    def http_post(method, args={})
      url = URI.parse(API_URL)
      tries = 3
      response = ""
      form_args = @encoder.encode(method, args)
      begin
        response = Net::HTTP.post_form(url, form_args).body
      rescue
        tries -= 1
          debug "DivShare\#http_post() failed: #{tries} tries remaining"
        if tries > 0
          retry
        else
          raise Divshare::ConnectionError, "Couldn't connect to #{API_URL} for '#{method}' using #{form_args.inspect}"
        end
      end
      response
    end
   
    # Outputs whatever is given to $stderr if debugging is enabled.
    def debug(*args)
      $stderr.puts(sprintf(*args)) if @debug
    end
  end
end
