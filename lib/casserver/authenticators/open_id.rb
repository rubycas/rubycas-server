require 'openid'
require 'openid/extensions/sreg'
require 'openid/extensions/pape'
require 'openid/store/memory'

# CURRENTLY UNIMPLEMENTED
# This is just starter code.
class CASServer::Authenticators::OpenID < CASServer::Authenticators::Base

  def validate(credentials)
    raise NotImplementedError, "The OpenID authenticator is not yet implemented. "+
      "See http://code.google.com/p/rubycas-server/issues/detail?id=36 if you are interested in helping this along."

    read_standard_credentials(credentials)

    store = OpenID::Store::Memory.new
    consumer = OpenID::Consumer.new({}, store)
  end
end
