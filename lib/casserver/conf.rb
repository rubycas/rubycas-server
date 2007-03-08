# load configuration
begin
  conf_file = File.dirname(File.expand_path(__FILE__))+"/../../config.yml"
  loaded_conf = HashWithIndifferentAccess.new(YAML.load_file(conf_file))
  
  if $CONF
    $CONF = loaded_conf.merge $CONF
  else
    $CONF = loaded_conf
  end
  
  begin
    # attempt to instantiate the authenticator
    $AUTH = $CONF[:authenticator][:class].constantize.new
  rescue NameError
    # the authenticator class hasn't yet been loaded, so lets try to load it from the casserver/authenticators directory
    auth_rb = $CONF[:authenticator][:class].underscore.gsub('cas_server/', '')
    require 'casserver/'+auth_rb
    $AUTH = $CONF[:authenticator][:class].constantize.new
  end
rescue
  if File.exists? conf_file
    raise "Your RubyCAS-Server configuration may be invalid."+
      " Please double-check check your config.yml file."+
      " Make sure that you are using spaces instead of tabs for your indentation!!" +
      "\n\nUNDERLYING EXCEPTION:\n#{$!}"
  else
    puts "\nCAS SERVER NOT YET CONFIGURED!!!\n"
    puts "\nIt appears that you have not yet created a configuration for the CAS server." +
      " \nYou should make a copy of the 'config.example.yml' file, name it 'config.yml'" + 
      " and edit it to match your desired configuration.\n\n"
    exit 1
  end
end

module CASServer
  module Conf
    DEFAULTS = {
      :login_ticket_expiry => 5.minutes,
      :service_ticket_expiry => 5.minutes, # CAS Protocol Spec, sec. 3.2.1 (recommended expiry time)
      :proxy_granting_ticket_expiry => 48.hours,
      :ticket_granting_ticket_expiry => 48.hours,
      :log => {:file => 'casserver.log', :level => 'DEBUG'},
      :uri_path => "/"
    }
  
    def [](key)
      $CONF[key] || DEFAULTS[key]
    end
    module_function "[]".intern
    
    def self.method_missing(method, *args)
      self[method]
    end
  end
end