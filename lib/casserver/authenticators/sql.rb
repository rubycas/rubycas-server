require 'casserver/authenticators/base'

begin
  require 'active_record'
rescue LoadError
  require 'rubygems'
  require 'active_record'
end

# Authenticates against a plain SQL table. 
# 
# This assumes that all of your users are stored in a table that has a 'username' 
# column and a 'password' column. When the user logs in, CAS conects to the 
# database and looks for a matching username/password in the users table. If a 
# matching username and password is found, authentication is successful.
#
# Any database backend supported by ActiveRecord can be used.
# 
# Config example:
#
#   authenticator:
#     class: CASServer::Authenticators::SQL
#     database:
#       adapter: mysql
#       database: some_database_with_users_table
#       username: root
#       password: 
#       server: localhost
#     user_table: users
#     username_column: username
#     password_column: password
#
class CASServer::Authenticators::SQL < CASServer::Authenticators::Base

  def validate(credentials)
    read_standard_credentials(credentials)
    
    raise CASServer::AuthenticatorError, "Cannot validate credentials because the authenticator hasn't yet been configured" unless @options
    raise CASServer::AuthenticatorError, "Invalid authenticator configuration!" unless @options[:database]
    
    CASUser.establish_connection @options[:database]
    CASUser.set_table_name @options[:user_table] || "users"
    
    username_column = @options[:username_column] || 'username'
    password_column = @options[:password_column] || 'password'
    
    results = CASUser.find(:all, :conditions => ["#{username_column} = ? AND #{password_column} = ?", @username, @password])
    
    if results.size > 0
      $LOG.warn("Multiple matches found for user '#{@username}'") if results.size > 1
      return true
    else
      return false
    end
  end
  
  class CASUser < ActiveRecord::Base
  end

end