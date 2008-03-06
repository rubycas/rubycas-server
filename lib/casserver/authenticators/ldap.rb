require 'casserver/authenticators/base'

begin
  require 'net/ldap'
rescue LoadError
  require 'rubygems'
  begin
    gem 'ruby-net-ldap', '~> 0.0.4'
  rescue Gem::LoadError
    $stderr.puts
    $stderr.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    $stderr.puts
    $stderr.puts "To use the LDAP/AD authenticator, you must first install the 'ruby-net-ldap' gem."
    $stderr.puts
    $stderr.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
  end
  require 'net/ldap'
end

# Basic LDAP authenticator. Should be compatible with OpenLDAP and other similar LDAP servers,
# although it hasn't been officially tested. See example config file for details on how
# to configure it.
class CASServer::Authenticators::LDAP < CASServer::Authenticators::Base
  def validate(credentials)
    read_standard_credentials(credentials)

    return false if @password.blank?
   
    raise CASServer::AuthenticatorError, "Cannot validate credentials because the authenticator hasn't yet been configured" unless @options
    raise CASServer::AuthenticatorError, "Invalid authenticator configuration!" unless @options[:ldap]
    raise CASServer::AuthenticatorError, "You must specify an ldap server in the configuration!" unless @options[:ldap][:server]
    
    raise CASServer::AuthenticatorError, "The username '#{@username}' contains invalid characters." if (@username =~ /[*\(\)\0\/]/)
    
    preprocess_username
    
    @ldap = Net::LDAP.new
    @ldap.host = @options[:ldap][:server]
    @ldap.port = @options[:ldap][:port] if @options[:ldap][:port]
    
    begin
      if @options[:ldap][:auth_user]
        bind_with_preauthentication
      else
        bind_directly
      end
    rescue Net::LDAP::LdapError => e
      raise CASServer::AuthenticatorError,
        "LDAP authentication failed with '#{e}'. Check your authenticator configuration."
    end
  end
  
  protected
    def default_username_attribute
      "uid"
    end
  
  private
    def preprocess_username
      # add prefix to username, if prefix was specified in the config
      @username = @options[:ldap][:username_prefix] + @username if @options[:ldap][:username_prefix]
    end
    
    def bind_with_preauthentication
      # If an auth_user is specified, we will connect ("pre-authenticate") to the
      # LDAP server using the authenticator account, and then attempt to bind as the
      # user who is actually trying to authenticate. Note that you need to set up 
      # the special authenticator account first. Also, auth_user must be the authenticator
      # user's full CN, which is probably not the same as their username.
      #
      # This pre-authentication process is necessary because binding can only be done
      # using the CN, so having just the username is not enough. We connect as auth_user, 
      # and then try to find the target user's CN based on the given username. Then we bind
      # as the target user to validate their credentials.
      
      raise CASServer::AuthenticatorError, "A password must be specified in the configuration for the authenticator user!" unless 
        @options[:ldap][:auth_password]
      
      @ldap.authenticate(@options[:ldap][:auth_user], @options[:ldap][:auth_password])
      
      username_attribute = options[:ldap][:username_attribute] || default_username_attribute
      
      filter = Net::LDAP::Filter.construct(@options[:ldap][:filter]) if 
        @options[:ldap][:filter] && !@options[:ldap][:filter].blank?
      username_filter = Net::LDAP::Filter.eq(username_attribute, @username)
      if filter
        filter &= username_filter
      else
        filter = username_filter
      end
      
      @ldap.bind_as(:base => @options[:ldap][:base], :password => @password, :filter => filter)
    end
    
    def bind_directly
      # When no auth_user is specified, we will try to connect directly as the user
      # who is trying to authenticate. Note that for this to work, the username must
      # be equivalent to the user's CN, and this is often not the case (for example,
      # in Active Directory, the username is the 'sAMAccountName' attribute, while the
      # user's CN is generally their full name.)
      
      cn = @username
      
      @ldap.authenticate(cn, @password)
      @ldap.bind
    end
end
