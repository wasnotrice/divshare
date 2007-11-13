require 'rubygems'
require 'hpricot'

module Divshare
  class File
    ATTRIBUTES = %w(file_id file_name file_description file_size downloads last_downloaded_at uploaded_at folder_title folder_id)
    attr_accessor *ATTRIBUTES
    
    def initialize(xml)
      ATTRIBUTES.each do |attr|
        value = xml.at(attr).inner_html
        instance_variable_set("@#{attr}", value)
      end
    end
    
    def to_s
      s = "#{file_name} <Divshare::File>\n"
      ATTRIBUTES.each do |a|
        s << sprintf(" %s: %s\n", a, self.send(a))
      end
      s
    end
  end
end