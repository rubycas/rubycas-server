
conf_defaults = {
  :expire_sessions => false,
  :login_ticket_expiry => 5.minutes,
  :service_ticket_expiry => 5.minutes, # CAS Protocol Spec, sec. 3.2.1 (recommended expiry time)
  :proxy_granting_ticket_expiry => 48.hours,
  :ticket_granting_ticket_expiry => 48.hours,
  :log => {:file => 'casserver.log', :level => 'DEBUG'},
  :uri_path => "/"
}

if $CONF
  $CONF.merge_defaults(conf_defaults)
else
  unless $APP_NAME && $APP_ROOT
    raise "Can't load the RubyCAS-Server configuration because $APP_NAME and/or $APP_ROOT are not defined."
  end

  require 'picnic/conf'
  $CONF = Picnic::Conf.new(conf_defaults)
  $CONF.load_from_file($APP_NAME, $APP_ROOT)
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
    if $CONF[:authenticator][:source]
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

unless $CONF[:authenticator]
  $stderr.puts
  $stderr.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  $stderr.puts
  $stderr.puts "You have not yet defined an authenticator for your CAS server!"
  $stderr.puts "Please consult your config file for details (most likely in"
  $stderr.puts "/etc/rubycas-server/config.yml)."
  $stderr.puts
  $stderr.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1
end


$CONF[:public_dir] = {
  :path => "/themes",
  :dir  => File.expand_path(File.dirname(__FILE__))+"/themes"
}


