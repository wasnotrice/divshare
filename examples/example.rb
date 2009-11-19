#/usr/bin/env ruby
require 'rubygems'
require 'divshare'

# Set these as needed
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