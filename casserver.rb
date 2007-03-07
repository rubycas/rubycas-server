#!/usr/bin/env ruby

Dir.chdir(File.dirname(File.expand_path(__FILE__))) if __FILE__ == $0

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
$LOG = CASServer::Utils::Logger.new(CASServer::Conf.log[:file])
$LOG.level = "CASServer::Utils::Logger::#{CASServer::Conf.log[:level]}".constantize

# do initialization stuff
def CASServer.create
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
  CASServer::Models::Base.establish_connection(CASServer::Conf.database)
  if CASServer::Conf.db_log
    CASServer::Models::Base.logger = Logger.new(CASServer::Conf.db_log[:file] || 'casserver_db.log')
    CASServer::Models::Base.logger.level = "CASServer::Utils::Logger::#{CASServer::Conf.db_log[:level] || 'DEBUG'}".constantize
  end

  case CASServer::Conf.server
  when "webrick", :webrick
    require 'webrick/httpserver'
    require 'camping/webrick'
    
    s = WEBrick::HTTPServer.new :BindAddress => "0.0.0.0", :Port => CASServer::Conf.port
    CASServer.create
    s.mount "/", WEBrick::CampingHandler, CASServer
  
    # This lets Ctrl+C shut down your server
    trap(:INT) do
      s.shutdown
    end
  
    s.start
    
  when "mongrel", :mongrel
    require 'rubygems'
    require 'mongrel/camping'
    
    
    CASServer.create
  
    server = Mongrel::Camping::start("0.0.0.0",CASServer::Conf.port,"/",CASServer)
    puts "\n** CASServer is running at http://localhost:#{CASServer::Conf.port}/ and logging to '#{CASServer::Conf.log[:file]}'"
    server.run.join
  
  when "fastcgi", :fastcgi
    require 'camping/fastcgi'
    Dir.chdir('/srv/www/camping/casserver/')
    
    CASServer.create
    Camping::FastCGI.start(CASServer)
    
  when "cgi", :cgi
    CASServer.create
    puts CASServer.run
    
  else
    if CASServer::Conf.server
      raise "The server setting '#{CASServer::Conf.server}' in your config.yml file is invalid."
    else
      raise "You must have a 'server' setting in your config.yml file. Please see the RubyCAS-Server documentation."
    end
  end
end 