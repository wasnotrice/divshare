require File.dirname(__FILE__) + '/spec_helper'
require 'divshare/file'

module FileSpecHelper
  # From http://www.divshare.com/integrate/api
  def one_file_xml
    xml = <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <response status="1">
        <files>
            <file>
                <file_id>123456-abc</file_id>
                <file_name>My Resume.doc</file_name>
                <file_description>Resume (Draft 3)</file_description>
                <file_size>0.4 MB</file_size>
                <downloads>4</downloads>
                <last_downloaded_at>1192417863</last_downloaded_at>
                <uploaded_at>1192454938</uploaded_at>
                <folder_title>Job Applications</folder_title>
                <folder_id>12345</folder_id>
            </file>
        </files>
    </response>
    EOS
    Hpricot(xml)/:file
  end
end

describe "A basic File" do
  include FileSpecHelper
  it "should set instance variables at creation" do
    file = Divshare::File.new(one_file_xml)
    file.instance_variables.map {|i| file.instance_variable_get(i) }.length.should == 9
  end
  
  it "should accept empty attributes in creation xml" do
    xml = one_file_xml
    (xml.at :file_description).swap("<file_description></file_description>")
    file = Divshare::File.new(xml)
    file.instance_variables.map {|i| file.instance_variable_get(i) }.delete_if {|i| i.empty? }.length.should == 8
  end
  
  it "shoould not treat empty attributes in creation xml as nils" do
    xml = one_file_xml
    (xml.at :file_description).swap("<file_description></file_description>")
    file = Divshare::File.new(xml)
    file.instance_variables.map {|i| file.instance_variable_get(i) }.delete_if {|i| i.nil? }.length.should == 9
  end    
end