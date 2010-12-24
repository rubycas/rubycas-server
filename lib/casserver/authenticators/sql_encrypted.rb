require 'casserver/authenticators/sql'

require 'digest/sha1'
require 'digest/sha2'
require 'crypt-isaac'

# This is a more secure version of the SQL authenticator. Passwords are encrypted
# rather than being stored in plain text.
#
# Based on code contributed by Ben Mabey.
#
# Using this authenticator requires some configuration on the client side. Please see
# http://code.google.com/p/rubycas-server/wiki/UsingTheSQLEncryptedAuthenticator
class CASServer::Authenticators::SQLEncrypted < CASServer::Authenticators::SQL
  # Include this module into your application's user model.
  #
  # Your model must have an 'encrypted_password' column where the password will be stored,
  # and an 'encryption_salt' column that will be populated with a random string before
  # the user record is first created.
  module EncryptedPassword
    def self.included(mod)
      raise "#{self} should be inclued in an ActiveRecord class!" unless mod.respond_to?(:before_save)
      mod.before_save :generate_encryption_salt
    end

    def encrypt(str)
      generate_encryption_salt unless encryption_salt
      Digest::SHA256.hexdigest("#{encryption_salt}::#{str}")
    end

    def password=(password)
      self[:encrypted_password] = encrypt(password)
    end

    def generate_encryption_salt
      self.encryption_salt = Digest::SHA1.hexdigest(Crypt::ISAAC.new.rand(2**31).to_s) unless
        encryption_salt
    end
  end

  def self.setup(options)
    super(options)
    user_model.__send__(:include, EncryptedPassword)
  end

  def validate(credentials)
    read_standard_credentials(credentials)
    raise_if_not_configured

    user_model = self.class.user_model

    username_column = @options[:username_column] || "username"
    encrypt_function = @options[:encrypt_function] || 'user.encrypted_password == Digest::SHA256.hexdigest("#{user.encryption_salt}::#{@password}")'

    $LOG.debug "#{self.class}: [#{user_model}] " + "Connection pool size: #{user_model.connection_pool.instance_variable_get(:@checked_out).length}/#{user_model.connection_pool.instance_variable_get(:@connections).length}"
    results = user_model.find(:all, :conditions => ["#{username_column} = ?", @username])
    user_model.connection_pool.checkin(user_model.connection)
    
    if results.size > 0
      $LOG.warn("Multiple matches found for user '#{@username}'") if results.size > 1
      user = results.first
      unless @options[:extra_attributes].blank?
        if results.size > 1
          $LOG.warn("#{self.class}: Unable to extract extra_attributes because multiple matches were found for #{@username.inspect}")
        else
          extract_extra(user)
              log_extra
        end
      end
      return eval(encrypt_function)
    else
      return false
    end
  end
end
