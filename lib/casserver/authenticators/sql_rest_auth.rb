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

    user_model = self.class.user_model

    username_column = @options[:username_column] || "email"

    $LOG.debug "#{self.class}: [#{user_model}] " + "Connection pool size: #{user_model.connection_pool.instance_variable_get(:@checked_out).length}/#{user_model.connection_pool.instance_variable_get(:@connections).length}"
    results = user_model.find(:all, :conditions => ["#{username_column} = ?", @username])
    user_model.connection_pool.checkin(user_model.connection)

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
    REST_AUTH_DIGEST_STRETCHES = $CONF.rest_auth_digest_streches
    REST_AUTH_SITE_KEY         = $CONF.rest_auth_site_key

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
end
