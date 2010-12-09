if @success
  xml.tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
    xml.tag!("cas:proxySuccess") do
      xml.tag!("cas:proxyTicket", @pt.to_s)
    end
  end
else
  xml.tag!("cas:serviceResponse", 'xmlns:cas' => "http://www.yale.edu/tp/cas") do
    xml.tag!("cas:proxyFailure", {:code => @error.code}, @error.to_s)
  end
end