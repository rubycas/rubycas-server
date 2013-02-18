# encoding: UTF-8
xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
if @success
  xml.tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
    xml.tag!("cas:authenticationSuccess") do
      xml.tag!("cas:user", @username.to_s)
      if @extra_attributes
        xml.tag!("cas:attributes") do
          @extra_attributes.each do |key, value|
            namespace_aware_key = key[0..3]=='cas:' ? key : 'cas:' + key 
            serialize_extra_attribute(xml, namespace_aware_key, value)
          end
        end
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