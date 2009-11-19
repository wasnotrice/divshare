divshare
========

Description
-----------

The divshare gem makes it easier to use the Divshare API. To use it, you need
to create a Divshare account and sign up for an API key.

Usage
-----

Here's a brief walkthrough of the basic operations (see `examples/` for more information):

    require 'divshare'

    # Set these for your divshare account
    api_key    = 'your api key'
    api_secret = 'your api secret'
    email      = 'your login email address'
    password   = 'your password'
    filename   = 'a file you want to upload'

    client = Divshare::Client.new(api_key, api_secret)
    client.login(email, password)
    all_my_files = client.get_user_files
    all_my_files.each do |f| 
      print "#{f.file_name} (#{f.file_size}) "
      puts "was last downloaded #{Time.at(f.last_downloaded_at.to_i)}"
    end
    ticket = client.get_upload_ticket
    uploaded_id = client.upload(ticket, filename)
    puts "#{filename} uploaded with new id: #{uploaded_id}"
    client.logout

Now, going through the same script step-by-step. Use your Divshare API
key and secret (comes with key) to create a client:

    client = Divshare::Client.new(api_key, api_secret)
    
Login using the credentials for your Divshare account:

    client.login(email, password)

Get an array of all of your files:

    all_my_files = client.get_user_files
    
Do something with the files:

    all_my_files.each do |f| 
      print "#{f.file_name} (#{f.file_size}) "
      puts "was last downloaded #{Time.at(f.last_downloaded_at.to_i)}"
    end

Upload a file, and capture its id:

    ticket = client.get_upload_ticket
    uploaded_id = client.upload(ticket, filename)

Logout

    client.logout

Installation
------------

Install using rubygems:

    sudo gem install divshare 

Or clone from github
    
    git clone git://github.com/wasnotrice/divshare.git