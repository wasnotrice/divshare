module Divshare
  
  # Manages the arguments send along with a POST to the DivShare API URL.
  # Takes care of organizing arguments and generating API signatures for
  # requests 
  class Encoder # :nodoc:
    attr_accessor :session_key

    def initialize(key, secret)
      @key, @secret = key, secret
    end
    
    # Prepares arguments for a post using the given method and arguments.
    # Returns a hash of arguments and values
    def prepare(method, args)
      temp_args = args.merge({'method' => method, 'api_key' => key})
      if @session_key #&& method.to_sym != :logout
        api_sig = sign(temp_args)
        temp_args.merge!({'api_session_key' => session_key, 'api_sig' => api_sig})
      end
      # Stringify keys and values
      post_args = Hash.new
      temp_args.each { |k, v| post_args[k.to_s] = v.to_s }
      post_args
    end

    # Generates the required MD5 signature as described in
    # http://www.divshare.com/integrate/api#sig
    def sign(args)
      Digest::MD5.hexdigest(string_to_sign(args))
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
      "#{@secret}#{@session_key}#{args_for_string.to_a.sort.flatten.join}"
    end
  end
end
