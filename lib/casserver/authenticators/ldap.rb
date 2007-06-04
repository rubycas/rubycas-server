require 'casserver/authenticators/base'

begin
  require 'net/ldap'
rescue LoadError
  require 'rubygems'
  gem 'ruby-net-ldap', '~> 0.0.4'
  require 'net/ldap'
end

class CASServer::Authenticators::LDAP < CASServer::Authenticators::Base
  def validate(credentials)
    read_standard_credentials(credentials)
    
    return false if @password.blank?
    
    raise CASServer::AuthenticatorError, "Cannot validate credentials because the authenticator hasn't yet been configured" unless @options
    raise CASServer::AuthenticatorError, "Invalid authenticator configuration!" unless @options[:ldap]
    raise CASServer::AuthenticatorError, "You must specify an ldap server in the configuration!" unless @options[:ldap][:server]
    
    raise CASServer::AuthenticatorError, "The username '#{@username}' contains invalid characters." if (@username =~ /[*\(\)\\\0\/]/)
    
    ldap = Net::LDAP.new
    ldap.host = @options[:ldap][:server]
    ldap.port = @options[:ldap][:port] if   @options[:ldap][:port]
    
    if @options[:ldap][:auth_user]
      raise CASServer::AuthenticatorError, "A password must be specified in the configuration for the authenticator user!" unless @options[:ldap][:auth_password]
      ldap.authenticate(@options[:ldap][:auth_user], @options[:ldap][:auth_password])
    end
    
    filter = "(#{@options[:ldap][:username_attribute] || default_username_attribute}=#{@username})"
    filter += " & (#{@options[:ldap][:filter]})" if @options[:ldap][:filter]
    
    result = ldap.bind_as(:base => @options[:ldap][:base], :filter => filter, :password => @password)
    
    return result
  end
  
  protected
  def default_username_attribute
    "uid"
  end
end