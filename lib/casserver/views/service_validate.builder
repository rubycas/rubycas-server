if @success
  xml.tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
    xml.tag!("cas:authenticationSuccess") do
      xml.tag!("cas:user", @username.to_s)
      @extra_attributes.each do |key, value|
        serialize_extra_attribute(xml, key, value)
      end
      if @pgtiou
        xml.tag!("cas:proxyGrantingTicket", @pgtiou.to_s)
      end
    end
  end
else
  xml.tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
    xml.tag!("cas:authenticationFailure", {:code => @error.code}, @error.to_s)
  end
end