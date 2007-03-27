require 'casserver/authenticators/base'

class CASServer::Authenticators::Test < CASServer::Authenticators::Base
  def validate(credentials)
    read_standard_credentials(credentials)
    
    raise CASServer::AuthenticatorError, "Username is 'do_error'!" if @username == 'do_error'
    
    return @username == "testuser" && @password == "testpassword"
  end
end