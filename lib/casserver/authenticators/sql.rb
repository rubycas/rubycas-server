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
# When replying to a CAS client's validation request, the server will normally
# provide the client with the authenticated user's username. However it is now
# possible for the server to provide the client with additional attributes.
# You can configure the SQL authenticator to provide data from additional
# columns in the users table by listing the names of the columns under the 
# 'extra_attributes' option. Note though that this functionality is experimental.
# It should work with RubyCAS-Client, but may or may not work with other CAS
# clients. 
#
# For example, with this configuration, the 'full_name' and 'access_level'
# columns will be provided to your CAS clients along with the username:
#
#   authenticator:
#     class: CASServer::Authenticators::SQL
#     database:
#       adapter: mysql
#       database: some_database_with_users_table
#     user_table: users
#     username_column: username
#     password_column: password
#     extra_attributes: full_name, access_level
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
      $LOG.warn("#{self.class}: Multiple matches found for user #{@username.inspect}") if results.size > 1
      
      unless @options[:extra_attributes].blank?
        if results.size > 1
          $LOG.warn("#{self.class}: Unable to extract extra_attributes because multiple matches were found for #{@username.inspect}")
        else
          user = results.first
          
          @extra_attributes = {}
          extra_attributes_to_extract.each do |col|
            @extra_attributes[col] = user.send(col)
          end
          
          if @extra_attributes.empty?
            $LOG.warn("#{self.class}: Did not read any extra_attributes for user #{@username.inspect} even though an :extra_attributes option was provided.")
          else
            $LOG.debug("#{self.class}: Read the following extra_attributes for user #{@username.inspect}: #{@extra_attributes.inspect}")
          end
        end
      end
      
      return true
    else
      return false
    end
  end
  
  class CASUser < ActiveRecord::Base
  end

end