require 'rubygems'
require 'hpricot'

module Divshare
  class DivshareFile
    ATTRIBUTES = %w(file_id file_name file_description file_size downloads last_downloaded_at uploaded_at folder_title folder_id)
    AUDIO = /^\.(mp3)$/i
    VIDEO = /^\.(avi|wmv|mov|mpg|asf)$/i
    DOCUMENT = /^\.(doc|pdf|ppt)$/i
    IMAGE = /^\.(jpg|gif|png)/i
    EMBED_TAGS = {
      :audio => "<object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,0,0\" width=\"335\" height=\"28\" id=\"divaudio2\"><param name=\"movie\" value=\"http://www.divshare.com/flash/audio?myId=INSERT_SLUG_HERE\" /><embed src=\"http://www.divshare.com/flash/audio?myId=INSERT_SLUG_HERE\" width=\"335\" height=\"28\" name=\"divaudio2\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\"></embed></object>",
      :video => "<object classid=\"clsid:d27cdb6e-ae6d-11cf-96b8-444553540000\" codebase=\"http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,18,0\" width=\"425\" height=\"374\" id=\"divflv\"><param name=\"movie\" value=\"http://www.divshare.com/flash/video?myId=INSERT_SLUG_HERE\" /><param name=\"allowFullScreen\" value=\"true\" /><embed src=\"http://www.divshare.com/flash/video?myId=INSERT_SLUG_HERE\" width=\"425\" height=\"374\" name=\"divflv\" allowfullscreen=\"true\" type=\"application/x-shockwave-flash\" pluginspage=\"http://www.macromedia.com/go/getflashplayer\"></embed></object>",
      :image => ""}
    
    
    attr_reader *ATTRIBUTES
    attr_reader :medium
    
    def initialize(xml)
      ATTRIBUTES.each do |attr|
        value = xml.at(attr).inner_html
        instance_variable_set("@#{attr}", value)
      end
      @medium = find_medium
    end
    
    def audio?
      @medium == :audio
    end
    
    def document?
      @medium == :document
    end
    
    def video?
      @medium == :video
    end
    
    def image?
      @medium == :image
    end
    
    def embed_tag
      self.send("#{medium}_embed_tag")
    end
    
    def to_s
      s = "#{file_name} <Divshare::DivshareFile>\n"
      ATTRIBUTES.each { |a| s << sprintf(" %s: %s\n", a, self.send(a)) }
      s
    end
    
    private
    def find_medium
      ext = File.extname(file_name)
      medium = case
        when AUDIO.match(ext): :audio
        when VIDEO.match(ext): :video
        when DOCUMENT.match(ext): :document
        when IMAGE.match(ext): :image
        else nil
      end
    end
    
    def audio_embed_tag
    end
    
    def video_embed_tag
      tag = <<-END_OF_TAG
<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,18,0" width="425" height="374" id="divflv">
  <param name="movie" value="http://www.divshare.com/flash/video?myId=[FILE ID]" />
  <param name="allowFullScreen" value="true" />
  <embed src="http://www.divshare.com/flash/video?myId=[FILE ID]" width="425" height="374" name="divflv" allowfullscreen="true" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer"></embed>
</object>
      END_OF_TAG
      tag.gsub('[FILE ID]', @file_id)
    end
  end
end