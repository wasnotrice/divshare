require 'rubygems'
require 'hpricot'

class Divshare::File
  attr_accessor :file_id, :file_name, :file_description, :file_size, :downloads, :last_downloaded_at, :uploaded_at, :folder_title, :folder_id

  def initialize(xml)
    %w(file_id file_name file_description file_size downloads last_downloaded_at uploaded_at folder_title folder_id).each do |attr|
      value = xml.at(attr).inner_html
      instance_variable_set("@#{attr}", value) if value
    end
  end
end