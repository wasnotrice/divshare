require File.dirname(__FILE__) + '/spec_helper'
require 'divshare/divshare_file'
include Divshare

module DivshareFileSpecHelper
  include DivshareMockXML
end

describe "A basic DivshareFile" do
  include DivshareFileSpecHelper
  before(:each) do
    @xml = Hpricot(get_one_file_xml)/:file
    @xml_with_blank = @xml.dup
    (@xml_with_blank.at :file_description).swap("<file_description></file_description>")
  end
  
  it "should set instance variables at creation" do
    file = DivshareFile.new(@xml)
    file.instance_variables.map {|i| file.instance_variable_get(i) }.length.should == 9
  end
  
  it "should accept empty attributes in creation xml" do
    file = DivshareFile.new(@xml_with_blank)
    file.instance_variables.map {|i| file.instance_variable_get(i) }.delete_if {|i| i.empty? }.length.should == 8
  end
  
  it "shoould not treat empty attributes in creation xml as nils" do
    file = DivshareFile.new(@xml_with_blank)
    file.instance_variables.map {|i| file.instance_variable_get(i) }.delete_if {|i| i.nil? }.length.should == 9
  end    
end