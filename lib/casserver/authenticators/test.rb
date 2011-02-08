require 'casserver/authenticators/base'

# Dummy authenticator used for testing.
# Accepts any username as valid as long as the password is "testpassword"; otherwise authentication fails.
# Raises an AuthenticationError when username is "do_error" (this is useful to test the Exception
# handling functionality).
class CASServer::Authenticators::Test < CASServer::Authenticators::Base
  def validate(credentials)
    read_standard_credentials(credentials)

    raise CASServer::AuthenticatorError, "Username is 'do_error'!" if @username == 'do_error'

    @extra_attributes[:test_string] = "testing!"
    @extra_attributes[:test_utf_string] = "Ютф"
    @extra_attributes[:test_numeric] = 123.45
    @extra_attributes[:test_serialized] = {:foo => 'bar', :alpha => [1,2,3]}

    valid_password = options[:password] || "testpassword"

    return @password == valid_password
  end
end
