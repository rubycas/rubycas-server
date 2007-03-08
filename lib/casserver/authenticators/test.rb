require 'casserver/authenticators/base'

class CASServer::Authenticators::Test < CASServer::Authenticators::Base
  def validate(credentials)
    read_standard_credentials(credentials)
    return @username == "testuser" && @password == "testpassword"
  end
end