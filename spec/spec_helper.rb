lib_path = File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift(lib_path) unless $:.include?(lib_path)
module Divshare
  module MockHTML
    module Valid
      def video_html
        return Hpricot(File.open(File.dirname(__FILE__) + "/fixtures/docs/divshare_mock_valid_video.html"))
      end
      
      def audio_html
        return Hpricot(File.open(File.dirname(__FILE__) + "/fixtures/docs/divshare_mock_valid_audio.html"))
      end
        
    end
  end
end



