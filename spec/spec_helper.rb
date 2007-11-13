lib_path = File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift(lib_path) unless $:.include?(lib_path)

module DivshareMockXML
  def get_user_info
    xml = <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <response status="1">
        <user_info>
            <user_fname>Rob</user_fname>
            <user_email>support@divshare.com</user_email>
        </user_info>
    </response>
    EOS
  end
end



