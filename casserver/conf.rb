# load configuration
begin
  $CONF = HashWithIndifferentAccess.new(YAML.load_file(File.dirname(File.expand_path(__FILE__))+
    "/../config.yml"))
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
  raise "Your RubyCAS-Server configuration may be invalid."+
    " Please double-check check your config.yml file.\n\nUNDERLYING PROBLEM:\n#{$!}"
end

module CASServer
  module Conf
    DEFAULTS = {
      :login_ticket_expiry => 5.minutes,
      :service_ticket_expiry => 5.minutes, # CAS Protocol Spec, sec. 3.2.1 (recommended expiry time)
      :proxy_granting_ticket_expiry => 48.hours,
      :ticket_granting_ticket_expiry => 48.hours
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