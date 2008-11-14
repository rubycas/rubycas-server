require 'casserver/authenticators/base'

require 'digest/sha1'

begin
  require 'active_record'
rescue LoadError
  require 'rubygems'
  require 'active_record'
end

# This is a of the SQL authenticator and it works nice with RestfulAuthentication. 
# Passwords are encrypted the same way as it done in RestfulAuthentication. 
# Before use you MUST configure rest_auth_digest_streches and rest_auth_site_key in 
# config. 
#
# Using this authenticator requires restful authentication plugin on rails (client) side.
#
# * git://github.com/technoweenie/restful-authentication.git
#
class CASServer::Authenticators::SQLRestAuth < CASServer::Authenticators::Base

  def validate(credentials)
    read_standard_credentials(credentials)
    
    raise CASServer::AuthenticatorError, "Cannot validate credentials because the authenticator hasn't yet been configured" unless @options
    raise CASServer::AuthenticatorError, "Invalid authenticator configuration!" unless @options[:database]
    
    CASUser.establish_connection @options[:database]
    CASUser.set_table_name @options[:user_table] || "users"
    
    username_column = @options[:username_column] || "email"
    
    results = CASUser.find(:all, :conditions => ["#{username_column} = ?", @username])
    
    if results.size > 0
      $LOG.warn("Multiple matches found for user '#{@username}'") if results.size > 1
      user = results.first
      return (user.crypted_password == user.encrypt(@password)) 
    else
      return false
    end
  end
  
  module EncryptedPassword

    # XXX: this constants MUST be defined in config. 
    # For more details # look at restful-authentication docs.
    #
    REST_AUTH_DIGEST_STRETCHES = CASServer::Conf.rest_auth_digest_streches
    REST_AUTH_SITE_KEY         = CASServer::Conf.rest_auth_site_key

    def self.included(mod)
      raise "#{self} should be inclued in an ActiveRecord class!" unless mod.respond_to?(:before_save)
    end
    
    def encrypt(password)
      password_digest(password, self.salt)
    end
    
    def secure_digest(*args)
      Digest::SHA1.hexdigest(args.flatten.join('--'))
    end

    def password_digest(password, salt)
      digest = REST_AUTH_SITE_KEY
      REST_AUTH_DIGEST_STRETCHES.times do
        digest = secure_digest(digest, salt, password, REST_AUTH_SITE_KEY)
      end
      digest
    end      
  end
  
  class CASUser < ActiveRecord::Base
    include EncryptedPassword
  end
end
