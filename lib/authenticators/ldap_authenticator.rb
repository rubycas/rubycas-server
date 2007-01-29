require File.dirname(File.expand_path(__FILE__))+'/base_authenticator'

begin
  require 'net/ldap'
rescue LoadError
  require 'rubygems'
  require 'net/ldap'
end

class CASServer::Authenticators::LDAP < CASServer::Authenticators::Base
  def validate(credentials)
    read_standard_credentials(credentials)
    
    
    ldap = connect_to_ldap
    
    
    raise "Couldn't connect to the LDAP server. Please check your ldap_connection config." unless ldap
    begin
      puts "trying to bind"
      return false unless ldap.bind
    rescue Net::LDAP::LdapError
      raise "Couldn't connect to the LDAP server using the given credentials: $!"
    end
    
    
    results = ldap.search(:base => @options['ldap_treebase'], 
                          :filter => @options['ldap_filter'] & 
                          Net::LDAP::Filter.eq( @options['ldap_username_attribute'] || default_username_attribute, @username ))

    return false unless results and not results.empty?
    raise "Got #{results.size} results for username '#{@username}'... but validation must match against only one entry!" if results.size > 1
    
    entry = results.first
    puts entry.inspect
    return @options['ldap_password_attribute'].nil? || entry.send(@options['ldap_password_attribute'].intern) == @password

  end
  
  protected
  def default_username_attribute
    "uid"
  end
  
  def connect_to_ldap
    connection_conf = @options[:ldap_server]
    if connection_conf[:auth]
      connection_conf[:username] = @username unless connection_conf[:username]
      connection_conf[:password] = @password unless connection_conf[:password]
    end
    
    ldap = Net::LDAP.new(connection_conf)
    
    raise "Couldn't connect to the LDAP server. Please check your ldap_connection config." unless ldap
    
    begin
      ldap.bind
    rescue Net::LDAP::LdapError
      # check if the username or password came from the config. if so then an inability to bind means that 
      # we have a configuration problem; but if we are connecting using the username/password from the
      # credentials we are trying to validate, then this is an authentication failure and we can just return false
      if @options[:ldap_server][:auth] and 
          (@options[:ldap_server][:auth][:username] or @options[:ldap_server][:auth][:password])
        raise "Couldn't connect to the LDAP server using username #{connection_conf[:username]}: $!"
      else
        return false
      end
    end
    
    return true
  end
end