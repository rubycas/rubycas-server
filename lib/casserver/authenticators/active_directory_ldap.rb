require 'casserver/authenticators/ldap'

# Slightly modified version of the LDAP authenticator for Microsoft's ActiveDirectory.
# The only difference is that the default_username_attribute for AD is 'sAMAccountName'
# rather than 'uid'.
class CASServer::Authenticators::ActiveDirectoryLDAP < CASServer::Authenticators::LDAP
  protected
  def default_username_attribute
    "sAMAccountName"
  end
end
