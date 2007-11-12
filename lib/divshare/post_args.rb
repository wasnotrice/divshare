module Divshare
  # This is a simple hash that initializes itself in a state appropriate to
  # the request. Converts all keys to strings.
  class PostArgs < Hash
    def initialize(client, method, args)
      post_args = args.merge({'method' => method, 'api_key' => client.api_key})
      if client.api_session_key
        api_sig = client.sign(method, post_args)
        post_args.merge!({'api_session_key' => client.api_session_key, 'api_sig' => api_sig})
      end
      post_args.each { |k,v| self[k.to_s] = v.to_s }
    end

    
  end
end
