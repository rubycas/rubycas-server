require File.dirname(File.expand_path(__FILE__))+'/ldap_authenticator'

class CASServer::Authenticators::ActiveDirectoryLDAP < CASServer::Authenticators::LDAP
  protected
  def default_username_attribute
    "sAMAccountName"
  end
end

@options = {}
@options['ldap_treebase'] = "cn=Users,dc=urbacon,dc=net"
@options['ldap_filter'] = Net::LDAP::Filter.eq( "objectClass", "person" )
@options['ldap_server'] = {:host => 'urbacon-ad01', :port => 389, :auth => :simple}

@auth = CASServer::Authenticators::ActiveDirectoryLDAP.new
@auth.configure(@options)

puts %{Result: #{@auth.validate(:username => "mzukowski", :password => "urbacon5")}}