require 'rubygems'
require 'hpricot'

module Divshare
  class DivshareFile
    ATTRIBUTES = %w(file_id file_name file_description file_size downloads last_downloaded_at uploaded_at folder_title folder_id)
    AUDIO = /^\.(mp3)$/i
    VIDEO = /^\.(avi|wmv|mov|mpg|asf)$/i
    DOCUMENT = /^\.(doc|pdf|ppt)$/i
    IMAGE = /^\.(jpg|gif|png)/i
    
    attr_accessor *ATTRIBUTES
    
    def initialize(xml)
      ATTRIBUTES.each do |attr|
        value = xml.at(attr).inner_html
        instance_variable_set("@#{attr}", value)
      end
    end
    
    def medium
      ext = File.extname(file_name)
      medium = case
        when AUDIO.match(ext): :audio
        when VIDEO.match(ext): :video
        when DOCUMENT.match(ext): :document
        when IMAGE.match(ext): :image
        else nil
      end
    end
    
    def audio?
      medium == :audio
    end
    
    def document?
      medium == :document
    end
    
    def video?
      medium == :video
    end
    
    def image?
      medium == :image
    end
    
    def to_s
      s = "#{file_name} <Divshare::DivshareFile>\n"
      ATTRIBUTES.each do |a|
        s << sprintf(" %s: %s\n", a, self.send(a))
      end
      s
    end
  end
end