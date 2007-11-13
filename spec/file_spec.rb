require File.dirname(__FILE__) + '/spec_helper'
require 'divshare/file'

module FileSpecHelper
  include DivshareMockXML
end

describe "A basic File" do
  include FileSpecHelper
  before(:each) do
    @xml = Hpricot(get_one_file_xml)/:file
    @xml_with_blank = @xml.dup
    (@xml_with_blank.at :file_description).swap("<file_description></file_description>")
  end
  
  it "should set instance variables at creation" do
    file = Divshare::File.new(@xml)
    file.instance_variables.map {|i| file.instance_variable_get(i) }.length.should == 9
  end
  
  it "should accept empty attributes in creation xml" do
    file = Divshare::File.new(@xml_with_blank)
    file.instance_variables.map {|i| file.instance_variable_get(i) }.delete_if {|i| i.empty? }.length.should == 8
  end
  
  it "shoould not treat empty attributes in creation xml as nils" do
    file = Divshare::File.new(@xml_with_blank)
    file.instance_variables.map {|i| file.instance_variable_get(i) }.delete_if {|i| i.nil? }.length.should == 9
  end    
end