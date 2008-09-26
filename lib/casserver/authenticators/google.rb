require 'casserver/authenticators/base'
require 'uri'
require 'net/http'
require 'net/https'

# Validates Google accounts against Google's authentication service -- in other 
# words, this authenticator allows users to log in to CAS using their
# Gmail/Google accounts.
class CASServer::Authenticators::Google < CASServer::Authenticators::Base
  def validate(credentials)
    read_standard_credentials(credentials)

    return false if @username.blank? || @password.blank?
   
    auth_data = {
      'Email'   => @username, 
      'Passwd'  => @password, 
      'service' => 'xapi', 
      'source'  => 'RubyCAS-Server',
      'accountType' => 'HOSTED_OR_GOOGLE'
    }
   
    url = URI.parse('https://www.google.com/accounts/ClientLogin')
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    res = http.start do |conn|
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data(auth_data,'&')
      conn.request(req)
    end
    
    case res
    when Net::HTTPSuccess
      true
    when Net::HTTPForbidden
      false
    else
      $LOG.error("Unexpected response from Google while validating credentials: #{res.inspect} ==> #{res.body}.")
      raise CASServer::AuthenticatorError, "Unexpected response received from Google while validating credentials."
    end

  end
end
