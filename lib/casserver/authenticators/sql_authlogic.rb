require 'casserver/authenticators/sql'

# These were pulled directly from Authlogic, and new ones can be added
# just by including new Crypto Providers
require File.dirname(__FILE__) + '/authlogic_crypto_providers/aes256'
require File.dirname(__FILE__) + '/authlogic_crypto_providers/bcrypt'
require File.dirname(__FILE__) + '/authlogic_crypto_providers/md5'
require File.dirname(__FILE__) + '/authlogic_crypto_providers/sha1'
require File.dirname(__FILE__) + '/authlogic_crypto_providers/sha512'

begin
  require 'active_record'
rescue LoadError
  require 'rubygems'
  require 'active_record'
end

# This is a version of the SQL authenticator that works nicely with Authlogic.
# Passwords are encrypted the same way as it done in Authlogic.
# Before use you this, you MUST configure rest_auth_digest_streches and rest_auth_site_key in
# config.
#
# Using this authenticator requires restful authentication plugin on rails (client) side.
#
# * git://github.com/binarylogic/authlogic.git
#
# Usage:

# authenticator:
#   class: CASServer::Authenticators::SQLAuthlogic
#   database:
#     adapter: mysql
#     database: some_database_with_users_table
#     user: root
#     password:
#     server: localhost
#   user_table: user
#   username_column: login
#   password_column: crypted_password
#   salt_column: password_salt
#   encryptor: Sha1
#   encryptor_options:
#     digest_format: --SALT--PASSWORD--
#     stretches: 1
#
class CASServer::Authenticators::SQLAuthlogic < CASServer::Authenticators::SQL

  def validate(credentials)
    read_standard_credentials(credentials)
    raise_if_not_configured

    user_model = self.class.user_model

    username_column = @options[:username_column] || "login"
    password_column = @options[:password_column] || "crypted_password"
    salt_column     = @options[:salt_column]

    log_connection_pool_size
    results = user_model.find(:all, :conditions => ["#{username_column} = ?", @username])
    user_model.connection_pool.checkin(user_model.connection)

    begin
      encryptor = eval("Authlogic::CryptoProviders::" + @options[:encryptor] || "Sha512")
    rescue
      $LOG.warn("Could not initialize Authlogic crypto class for '#{@options[:encryptor]}'")
      encryptor = Authlogic::CryptoProviders::Sha512
    end

    @options[:encryptor_options].each do |name, value|
      encryptor.send("#{name}=", value) if encryptor.respond_to?("#{name}=")
    end

    if results.size > 0
      $LOG.warn("Multiple matches found for user '#{@username}'") if results.size > 1
      user = results.first
      tokens = [@password, (not salt_column.nil?) && user.send(salt_column) || nil].compact
      crypted = user.send(password_column)

      unless @options[:extra_attributes].blank?
        if results.size > 1
          $LOG.warn("#{self.class}: Unable to extract extra_attributes because multiple matches were found for #{@username.inspect}")
        else
          extract_extra(user)
          log_extra
        end
      end

      return encryptor.matches?(crypted, tokens)
    else
      return false
    end
  end
end
