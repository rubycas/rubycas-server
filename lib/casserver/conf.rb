# load configuration

begin
  if $CONFIG_FILE
    conf_file = $CONFIG_FILE
  else
    conf_file = etc_conf = "/etc/rubycas-server/config.yml"
    unless File.exists? conf_file 
      # can use local config.yml file in case we're running non-gem installation
      conf_file = File.dirname(File.expand_path(__FILE__))+"/../../config.yml"
    end
  end

  unless File.exists? conf_file  
    require 'fileutils'
    
    example_conf_file = File.expand_path(File.dirname(File.expand_path(__FILE__))+"/../../config.example.yml")
    puts "\nCAS SERVER NOT YET CONFIGURED!!!\n"
    puts "\nAttempting to copy sample configuration from '#{example_conf_file}' to '#{etc_conf}'...\n"
    
    begin
      FileUtils.mkdir("/etc/rubycas-server") unless File.exists? "/etc/rubycas-server"
      FileUtils.cp(example_conf_file, etc_conf)
    rescue Errno::EACCES
      puts "\nIt appears that you do not have permissions to create the '#{etc_conf}' file. Try running this command using sudo (as root).\n"
      exit 2
    rescue
      puts "\nFor some reason the '#{etc_conf}' file could not be created. You'll have to copy the file manually." +
        " Use '#{example_conf_file}' as a template.\n"  
      exit 2
    end
    
    puts "\nA sample configuration has been created for you in '#{etc_conf}'. Please edit this file to" +
      " suit your needs and then run rubycas-server again.\n"
    exit 1
  end
 
  loaded_conf = HashWithIndifferentAccess.new(YAML.load_file(conf_file))
  
  if $CONF
    $CONF = loaded_conf.merge $CONF
  else
    $CONF = loaded_conf
  end
 
  if $CONF[:authenticator].instance_of? Array
    $CONF[:authenticator].each_index { |auth_index| $CONF[:authenticator][auth_index] = HashWithIndifferentAccess.new($CONF[:authenticator][auth_index])}
  end

  $AUTH = []
  begin
    # attempt to instantiate the authenticator
    if $CONF[:authenticator].instance_of? Array
      $CONF[:authenticator].each { |authenticator| $AUTH << authenticator[:class].constantize.new}
    else
      $AUTH << $CONF[:authenticator][:class].constantize.new
    end
  rescue NameError
    if $CONF[:authenticator].instance_of? Array
      $CONF[:authenticator].each do |authenticator|
        if !authenticator[:source].nil?
          # config.yml explicitly names source file
          require authenticator[:source]
        else
          # the authenticator class hasn't yet been loaded, so lets try to load it from the casserver/authenticators directory
          auth_rb = authenticator[:class].underscore.gsub('cas_server/', '')
          require 'casserver/'+auth_rb
        end
        $AUTH << authenticator[:class].constantize.new
      end
    else
      if !$CONF[:authenticator][:source].nil?
        # config.yml explicitly names source file
        require $CONF[:authenticator][:source]
      else
        # the authenticator class hasn't yet been loaded, so lets try to load it from the casserver/authenticators directory
        auth_rb = $CONF[:authenticator][:class].underscore.gsub('cas_server/', '')
        require 'casserver/'+auth_rb
      end

      $AUTH << $CONF[:authenticator][:class].constantize.new
    end
  end
rescue
    raise "Your RubyCAS-Server configuration may be invalid."+
      " Please double-check check your config.yml file."+
      " Make sure that you are using spaces instead of tabs for your indentation!!" +
      "\n\nUNDERLYING EXCEPTION:\n#{$!}"
end

module CASServer
  module Conf
    DEFAULTS = {
      :expire_sessions => false,
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
