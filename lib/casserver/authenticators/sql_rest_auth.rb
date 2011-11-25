require 'casserver/authenticators/sql_encrypted'

require 'digest/sha1'

begin
  require 'active_record'
rescue LoadError
  require 'rubygems'
  require 'active_record'
end

# This is a version of the SQL authenticator that works nicely with RestfulAuthentication.
# Passwords are encrypted the same way as it done in RestfulAuthentication.
# Before use you this, you MUST configure rest_auth_digest_streches and rest_auth_site_key in
# config.
#
# Using this authenticator requires restful authentication plugin on rails (client) side.
#
# * git://github.com/technoweenie/restful-authentication.git
#
class CASServer::Authenticators::SQLRestAuth < CASServer::Authenticators::SQLEncrypted

  def validate(credentials)
    read_standard_credentials(credentials)
    raise_if_not_configured

    raise CASServer::AuthenticatorError, "You must specify a 'site_key' in the SQLRestAuth authenticator's configuration!" unless  @options[:site_key]
    raise CASServer::AuthenticatorError, "You must specify 'digest_streches' in the SQLRestAuth authenticator's configuration!" unless  @options[:digest_streches]

    user_model = self.class.user_model

    username_column = @options[:username_column] || "email"

    $LOG.debug "#{self.class}: [#{user_model}] " + "Connection pool size: #{user_model.connection_pool.instance_variable_get(:@checked_out).length}/#{user_model.connection_pool.instance_variable_get(:@connections).length}"
    results = user_model.find(:all, :conditions => ["#{username_column} = ?", @username])
    user_model.connection_pool.checkin(user_model.connection)

    if results.size > 0
      $LOG.warn("Multiple matches found for user '#{@username}'") if results.size > 1
      user = results.first
      if user.crypted_password == user.encrypt(@password,@options[:site_key],@options[:digest_streches])
        unless @options[:extra_attributes].blank?
          extract_extra(user)
          log_extra
        end
        return true
      else
        return false
      end
    else
      return false
    end
  end

  def self.setup(options)
    super(options)
    user_model.__send__(:include, EncryptedPassword)
  end

  module EncryptedPassword

    def self.included(mod)
      raise "#{self} should be inclued in an ActiveRecord class!" unless mod.respond_to?(:before_save)
    end

    def encrypt(password,site_key,digest_streches)
      password_digest(password, self.salt,site_key,digest_streches)
    end

    def secure_digest(*args)
      Digest::SHA1.hexdigest(args.flatten.join('--'))
    end

    def password_digest(password, salt,site_key,digest_streches)
      digest = site_key
      digest_streches.times do
        digest = secure_digest(digest, salt, password, site_key) 
      end
      digest
    end
  end
end
