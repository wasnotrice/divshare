require File.dirname(__FILE__) + '/spec_helper'
require 'divshare/divshare_file'
include Divshare

module DivshareFileSpecHelper
  include DivshareMockXML
end

describe "A DivshareFile created with an empty file description" do
  include DivshareFileSpecHelper
  before(:each) do
    @xml = Hpricot(get_one_file_xml)/:file
    @xml_with_blank = @xml.dup
    (@xml_with_blank.at :file_description).swap("<file_description></file_description>")
    @file = DivshareFile.new(@xml_with_blank)
  end

  it "should treat an empty attribute in creation xml as an empty string" do
    @file.file_description.should == ""
  end

end

describe "A basic DivshareFile", :shared => true do
  include DivshareFileSpecHelper

  it "should set instance variables at creation" do
    @file.instance_variables.map {|i| @file.instance_variable_get(i) }.length.should == 10
  end
    
end

describe "An audio DivshareFile" do
  include DivshareFileSpecHelper
  before(:each) do
    @xml = Hpricot(get_one_file_xml)/:file
    @file_name = "audio.mp3"
    @xml.at(:file_name).swap("<file_name>#{@file_name}</file_name>")
    @file = DivshareFile.new(@xml)
  end
  it_should_behave_like "A basic DivshareFile"
  
  it "should know it is audio" do
    @file.should be_audio
  end
  
  it "should not think it is video, image, or document" do
    @file.should_not be_video
    @file.should_not be_image
    @file.should_not be_document
  end
end

describe "An image DivshareFile" do
  include DivshareFileSpecHelper
  before(:each) do
    @xml = Hpricot(get_one_file_xml)/:file
    @file_name = "image.jpg"
    @xml.at(:file_name).swap("<file_name>#{@file_name}</file_name>")
    @file = DivshareFile.new(@xml)
  end
  it_should_behave_like "A basic DivshareFile"
  
  it "should know it is an image" do
    @file.should be_image
  end
  
  it "should not think it is video, audio, or document" do
    @file.should_not be_video
    @file.should_not be_audio
    @file.should_not be_document
  end
end

describe "A video DivshareFile" do
  include DivshareFileSpecHelper
  before(:each) do
    @xml = Hpricot(get_one_file_xml)/:file
    @file_name = "video.mov"
    @xml.at(:file_name).swap("<file_name>#{@file_name}</file_name>")
    @file = DivshareFile.new(@xml)
  end
  it_should_behave_like "A basic DivshareFile"
  
  it "should know it is video" do
    @file.should be_video
  end
  
  it "should not think it is audio, image, or document" do
    @file.should_not be_audio
    @file.should_not be_image
    @file.should_not be_document
  end
  
  it "should generate a good embed tag" do
    tag = <<-END_OF_TAG
<object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" codebase="http://fpdownload.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=9,0,18,0" width="425" height="374" id="divflv">
  <param name="movie" value="http://www.divshare.com/flash/video?myId=#{@file.file_id}" />
  <param name="allowFullScreen" value="true" />
  <embed src="http://www.divshare.com/flash/video?myId=#{@file.file_id}" width="425" height="374" name="divflv" allowfullscreen="true" type="application/x-shockwave-flash" pluginspage="http://www.macromedia.com/go/getflashplayer"></embed>
</object>
    END_OF_TAG
    @file.embed_tag.should == tag
  end
end


describe "A document DivshareFile" do
  include DivshareFileSpecHelper
  before(:each) do
    @xml = Hpricot(get_one_file_xml)/:file
    @file = DivshareFile.new(@xml)
  end
  it_should_behave_like "A basic DivshareFile"
  
  it "should know it is a document" do
    @file.should be_document
  end
  
  it "should not think it is video, image, or audio" do
    @file.should_not be_video
    @file.should_not be_image
    @file.should_not be_audio
  end
  
end