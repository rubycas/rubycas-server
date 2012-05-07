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
#     ignore_type_column: true # indicates if you want to ignore Single Table Inheritance 'type' field
#     extra_attributes: full_name, access_level
#
class CASServer::Authenticators::SQL < CASServer::Authenticators::Base
  def self.setup(options)
    raise CASServer::AuthenticatorError, "Invalid authenticator configuration!" unless options[:database]

    user_model_name = "CASUser_#{options[:auth_index]}"
    $LOG.debug "CREATING USER MODEL #{user_model_name}"

    class_eval %{
      class #{user_model_name} < ActiveRecord::Base
      end
    }

    @user_model = const_get(user_model_name)
    @user_model.establish_connection(options[:database])
    @user_model.set_table_name(options[:user_table] || 'users')
    @user_model.inheritance_column = 'no_inheritance_column' if options[:ignore_type_column]
  end

  def self.user_model
    @user_model
  end

  def validate(credentials)
    read_standard_credentials(credentials)
    raise_if_not_configured
    
    $LOG.debug "#{self.class}: [#{user_model}] " + "Connection pool size: #{user_model.connection_pool.instance_variable_get(:@checked_out).length}/#{user_model.connection_pool.instance_variable_get(:@connections).length}"
    user_model.connection_pool.checkin(user_model.connection)
       
    if matching_users.size > 0
      $LOG.warn("#{self.class}: Multiple matches found for user #{@username.inspect}") if matching_users.size > 1
      
      unless @options[:extra_attributes].blank?
        if matching_users.size > 1
          $LOG.warn("#{self.class}: Unable to extract extra_attributes because multiple matches were found for #{@username.inspect}")
        else
          user = matching_users.first

          extract_extra(user)
          log_extra
        end
      end

      return true
    else
      return false
    end
  end

  protected

  def user_model
    self.class.user_model
  end

  def username_column
    @options[:username_column] || 'username'
  end
    
  def password_column
    @options[:password_column] || 'password'
  end

  def raise_if_not_configured
    raise CASServer::AuthenticatorError.new(
      "Cannot validate credentials because the authenticator hasn't yet been configured"
    ) unless @options
  end

  def extract_extra user
    @extra_attributes = {}
    extra_attributes_to_extract.each do |col|
      @extra_attributes[col] = user.send(col)
    end
  end

  def log_extra
    if @extra_attributes.empty?
      $LOG.warn("#{self.class}: Did not read any extra_attributes for user #{@username.inspect} even though an :extra_attributes option was provided.")
    else
      $LOG.debug("#{self.class}: Read the following extra_attributes for user #{@username.inspect}: #{@extra_attributes.inspect}")
    end
  end

  def matching_users
    user_model.find(:all, :conditions => ["#{username_column} = ? AND #{password_column} = ?", @username, @password])
  end
end
