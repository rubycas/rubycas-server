$: << File.dirname(File.expand_path(__FILE__))
require 'casserver/environment'

$APP_PATH ||= File.dirname(File.expand_path(__FILE__))

# change to current directory when invoked on its own
Dir.chdir($APP_PATH) if __FILE__ == $0

$: << $APP_PATH + "/../vendor/isaac_0.9.1"
require 'crypt/ISAAC'

require 'active_support'
require 'yaml'


# Camping.goes must be called after the authenticator class is loaded, otherwise weird things happen
Camping.goes :CASServer

$CONFIG_FILE ||= '/etc/rubycas-server/config.yml'

# for some reason this makes JRuby happy
class CASServer::Models::Base
end

CASServer.picnic!

$CONF[:expire_sessions] ||= false
$CONF[:login_ticket_expiry] ||= 5.minutes
$CONF[:service_ticket_expiry] ||= 5.minutes # CAS Protocol Spec, sec. 3.2.1 (recommended expiry time)
$CONF[:proxy_granting_ticket_expiry] ||= 48.hours
$CONF[:ticket_granting_ticket_expiry] ||= 48.hours
$CONF[:log] ||= {:file => 'casserver.log', :level => 'DEBUG'}
$CONF[:uri_path] ||= "/"

unless $CONF[:authenticator]
  $stderr.puts
  $stderr.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  $stderr.puts
  $stderr.puts "You have not yet defined an authenticator for your CAS server!"
  $stderr.puts "Please consult your config file at #{$CONFIG_FILE.inspect} for details."
  $stderr.puts
  $stderr.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1
end

require 'casserver/utils'
require 'casserver/models'
require 'casserver/cas'
require 'casserver/views'
require 'casserver/controllers'

if $CONF[:authenticator].instance_of? Array
  $CONF[:authenticator].each_index do |auth_index| 
    $CONF[:authenticator][auth_index] = HashWithIndifferentAccess.new($CONF[:authenticator][auth_index])
  end
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

$CONF[:public_dir] = {
  :path => "/themes",
  :dir  => File.expand_path(File.dirname(__FILE__))+"/themes"
}

def CASServer.create
  $LOG.info "Creating RubyCAS-Server..."
  CASServer::Models::Base.establish_connection(CASServer::Conf.database)
  CASServer::Models.create_schema
  
  CASServer::Models::ServiceTicket.cleanup_expired(CASServer::Conf.service_ticket_expiry)
  CASServer::Models::LoginTicket.cleanup_expired(CASServer::Conf.login_ticket_expiry)
  CASServer::Models::ProxyGrantingTicket.cleanup_expired(CASServer::Conf.proxy_granting_ticket_expiry)
  CASServer::Models::TicketGrantingTicket.cleanup_expired(CASServer::Conf.ticket_granting_ticket_expiry)
end


CASServer.start_picnic
