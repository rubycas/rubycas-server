#!/usr/bin/env ruby

require 'rubygems'
require 'camping'

require 'active_support'
require 'yaml'

# enable xhtml source code indentation for debugging views
Markaby::Builder.set(:indent, 2)

# seed the random number generator (ruby does this by default, but it doesn't hurt to do it here just to be sure)
srand

# Camping.goes must be called after the authenticator class is loaded, otherwise weird things happen
Camping.goes :CASServer

module CASServer  
end

require 'casserver/utils'
require 'casserver/models'
require 'casserver/cas'
require 'casserver/conf'
require 'casserver/views'
require 'casserver/controllers'

# init the logger
$LOG = CASServer::Utils::Logger.new($CONF[:log][:file] || 'casserver.log')
$LOG.level = "CASServer::Utils::Logger::#{CASServer::Conf.log[:level] || 'DEBUG'}".constantize

# do initialization stuff
def CASServer.create
  CASServer::Models::Base.establish_connection(CASServer::Conf.database)
  if CASServer::Conf.db_log
    CASServer::Models::Base.logger = Logger.new(CASServer::Conf.db_log[:file] || 'casserver_db.log')
    CASServer::Models::Base.logger.level = "CASServer::Utils::Logger::#{CASServer::Conf.db_log[:level] || 'DEBUG'}".constantize
  end

  CASServer::Models.create_schema
  
  $LOG.info("RubyCAS-Server initialized.")
  
  $LOG.debug("Configuration is:\n#{$CONF.to_yaml}")
  $LOG.debug("Authenticator is: #{$AUTH}")
  
  CASServer::Models::ServiceTicket.cleanup_expired(CASServer::Conf.service_ticket_expiry)
  CASServer::Models::LoginTicket.cleanup_expired(CASServer::Conf.login_ticket_expiry)
  CASServer::Models::ProxyGrantingTicket.cleanup_expired(CASServer::Conf.proxy_granting_ticket_expiry)
  CASServer::Models::TicketGrantingTicket.cleanup_expired(CASServer::Conf.ticket_granting_ticket_expiry)
end


# this gets run if we launch directly (i.e. `ruby casserver.rb` rather than `camping casserver`)
if __FILE__ == $0
  CASServer.create
  puts CASServer.run
end 