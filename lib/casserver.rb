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

def CASServer.create
  CASServer::Models::Base.establish_connection($CONF[:database])
  CASServer::Models.create_schema
  
  CASServer::Models::ServiceTicket.cleanup_expired($CONF[:service_ticket_expiry])
  CASServer::Models::LoginTicket.cleanup_expired($CONF[:login_ticket_expiry])
  CASServer::Models::ProxyGrantingTicket.cleanup_expired($CONF[:proxy_granting_ticket_expiry])
  CASServer::Models::TicketGrantingTicket.cleanup_expired($CONF[:ticket_granting_ticket_expiry])
end

