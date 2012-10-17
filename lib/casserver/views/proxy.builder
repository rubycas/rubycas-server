# encoding: UTF-8
xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
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