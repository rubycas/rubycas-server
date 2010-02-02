unless Object.const_defined?(:Picnic)
  $APP_NAME ||= 'rubycas-server'
  $APP_ROOT ||= File.expand_path(File.dirname(__FILE__)+'/..')

  require 'casserver/load_picnic'
end

require 'yaml'
require 'markaby'

require "casserver/conf"
require "picnic/logger"

$: << File.dirname(File.expand_path(__FILE__))

$: << File.expand_path("#{File.dirname(__FILE__)}/../vendor/isaac_0.9.1")
require 'crypt/ISAAC'

Camping.goes :CASServer

Picnic::Logger.init_global_logger!

require "casserver/utils"
require "casserver/models"
require "casserver/cas"
require "casserver/views"
require "casserver/controllers"
require "casserver/localization"

module CASServer
  # Release database connections back to the pool after each request.
  # This is necessary to prevent the connection pool from filling up with
  # hanging connections (Rails does this automatically, but Camping does not).
  def service(*a)
    r = super
    ActiveRecord::Base.clear_active_connections!
    return r
  end
end

def CASServer.create
  $LOG.info "Creating RubyCAS-Server with pid #{Process.pid}."


  CASServer::Models::Base.establish_connection($CONF.database) unless CASServer::Models::Base.connected?
  CASServer::Models.create_schema

  # setup all the authenticators
  $AUTH.zip($CONF.authenticator).each_with_index{ |auth_conf, index|
    auth, conf = auth_conf
    $LOG.debug "About to setup #{auth} with #{conf.inspect}..."
    auth.setup(conf.merge(:auth_index => index)) if auth.respond_to?(:setup)
    $LOG.debug "Done setting up #{auth}."
  }

  #TODO: these warnings should eventually be deleted
  if $CONF.service_ticket_expiry
    $LOG.warn "The 'service_ticket_expiry' option has been renamed to 'maximum_unused_service_ticket_lifetime'. Please make the necessary change to your config file!"
    $CONF.maximum_unused_service_ticket_lifetime ||= $CONF.service_ticket_expiry
  end
  if $CONF.login_ticket_expiry
    $LOG.warn "The 'login_ticket_expiry' option has been renamed to 'maximum_unused_login_ticket_lifetime'. Please make the necessary change to your config file!"
    $CONF.maximum_unused_login_ticket_lifetime ||= $CONF.login_ticket_expiry
  end
  if $CONF.ticket_granting_ticket_expiry || $CONF.proxy_granting_ticket_expiry
    $LOG.warn "The 'ticket_granting_ticket_expiry' and 'proxy_granting_ticket_expiry' options have been renamed to 'maximum_session_lifetime'. Please make the necessary change to your config file!"
    $CONF.maximum_session_lifetime ||= $CONF.ticket_granting_ticket_expiry || $CONF.proxy_granting_ticket_expiry
  end

  if $CONF.maximum_session_lifetime
    CASServer::Models::ServiceTicket.cleanup($CONF.maximum_session_lifetime, $CONF.maximum_unused_service_ticket_lifetime)
    CASServer::Models::LoginTicket.cleanup($CONF.maximum_session_lifetime, $CONF.maximum_unused_login_ticket_lifetime)
    CASServer::Models::ProxyGrantingTicket.cleanup($CONF.maximum_session_lifetime)
    CASServer::Models::TicketGrantingTicket.cleanup($CONF.maximum_session_lifetime)
  end
end

