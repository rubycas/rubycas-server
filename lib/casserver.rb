#!/usr/bin/env ruby

# change to current directory when invoked on its own
Dir.chdir(File.dirname(File.expand_path(__FILE__))) if __FILE__ == $0

# add current directory to load path
$CASSERVER_HOME = File.dirname(File.expand_path(__FILE__))
$: << $CASSERVER_HOME

require 'rubygems'

# make things backwards-compatible for rubygems < 0.9.0
unless Object.method_defined? :gem
  alias gem require_gem
end

gem 'camping', '~> 1.5'
require 'camping'

require 'active_support'
require 'yaml'

# enable xhtml source code indentation for debugging views
#Markaby::Builder.set(:indent, 2)

# seed the random number generator (ruby does this by default, but it doesn't hurt to do it here just to be sure)
srand

# Camping.goes must be called after the authenticator class is loaded, otherwise weird things happen
Camping.goes :CASServer

module CASServer
  def init_logger
    $LOG = CASServer::Utils::Logger.new(CASServer::Conf.log[:file])
    $LOG.level = "CASServer::Utils::Logger::#{CASServer::Conf.log[:level]}".constantize
  end
  module_function :init_logger

  def init_db_logger
    begin
      if CASServer::Conf.db_log
        log_file = CASServer::Conf.db_log[:file] || 'casserver_db.log'
        CASServer::Models::Base.logger = Logger.new(log_file)
        CASServer::Models::Base.logger.level = "CASServer::Utils::Logger::#{CASServer::Conf.db_log[:level] || 'DEBUG'}".constantize
      end
    rescue Errno::EACCES => e
      $LOG.warn "Can't write to database log file at '#{log_file}': #{e}"
    end
  end
  module_function :init_db_logger

end

require 'casserver/utils'
require 'casserver/models'
require 'casserver/cas'
require 'casserver/conf'
require 'casserver/views'
require 'casserver/controllers'

CASServer.init_logger

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
if __FILE__ == $0 || $RUN
  CASServer::Models::Base.establish_connection(CASServer::Conf.database)
  CASServer.init_db_logger unless CASServer::Conf.server.to_s == 'mongrel'
  
  require 'casserver/postambles'
  include CASServer::Postambles

  if $PID_FILE && (CASServer::Conf.server.to_s != 'mongrel' || CASServer::Conf.server.to_s != 'webrick')
    $LOG.warn("Unable to create a pid file. You must use mongrel or webrick for this feature.")
  end

  require 'casserver/version'
  puts
  puts "*** Starting RubyCAS-Server #{CASServer::VERSION::STRING} using codebase at #{$CASSERVER_HOME}"


  begin
    raise NoMethodError if CASServer::Conf.server.nil?
    send(CASServer::Conf.server)
  rescue NoMethodError
    # FIXME: this rescue can sometime report the incorrect error messages due to other underlying problems
    #         raising a NoMethodError
    if CASServer::Conf.server
      raise "The server setting '#{CASServer::Conf.server}' in your config.yml file is invalid."
    else
      raise "You must have a 'server' setting in your config.yml file. Please see the RubyCAS-Server documentation."
    end
  end

end 
