require File.dirname(File.expand_path(__FILE__))+'/ldap'

class CASServer::Authenticators::ActiveDirectoryLDAP < CASServer::Authenticators::LDAP
  protected
  def default_username_attribute
    "sAMAccountName"
  end
end
