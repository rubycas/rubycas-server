require 'casserver/authenticators/base'

require 'digest/sha1'
require 'digest/sha2'

$: << File.dirname(File.expand_path(__FILE__)) + "/../../../vendor/isaac_0.9.1"
require 'crypt/ISAAC'

begin
  require 'active_record'
rescue LoadError
  require 'rubygems'
  require 'active_record'
end

# This is a more secure version of the SQL authenticator. Passwords are encrypted 
# rather than being stored in plain text.
#
# Based on code contributed by Ben Mabey.
#
# Using this authenticator requires some configuration on the client side. Please see
# http://code.google.com/p/rubycas-server/wiki/UsingTheSQLEncryptedAuthenticator
class CASServer::Authenticators::SQLEncrypted < CASServer::Authenticators::Base

  def validate(credentials)
    read_standard_credentials(credentials)
    
    raise CASServer::AuthenticatorError, "Cannot validate credentials because the authenticator hasn't yet been configured" unless @options
    raise CASServer::AuthenticatorError, "Invalid authenticator configuration!" unless @options[:database]
    
    CASUser.establish_connection @options[:database]
    CASUser.set_table_name @options[:user_table] || "users"
    
    username_column = @options[:username_column] || "username"
    encrypt_function = @options[:encrypt_function] || 'user.encrypted_password == Digest::SHA256.hexdigest("#{user.encryption_salt}::#{@password}")'
    
    results = CASUser.find(:all, :conditions => ["#{username_column} = ?", @username])
    
    if results.size > 0
      $LOG.warn("Multiple matches found for user '#{@username}'") if results.size > 1
      user = results.first
      return eval(encrypt_function)
    else
      return false
    end
  end
  
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
  
  class CASUser < ActiveRecord::Base
    include EncryptedPassword
  end
end
