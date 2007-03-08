require 'casserver/authenticators/base'

begin
  require 'active_record'
rescue LoadError
  require 'rubygems'
  require 'active_record'
end

class CASServer::Authenticators::SQL < CASServer::Authenticators::Base

  def validate(credentials)
    read_standard_credentials(credentials)
    
    raise "Cannot validate credentials because the authenticator hasn't yet been configured" unless @options
    raise "Invalid authenticator configuration!" unless @options[:database]
    
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