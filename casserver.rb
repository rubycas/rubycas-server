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
  DEFAULT_LOGIN_TICKET_EXPIRY = 5.minutes
  DEFAULT_SERVICE_TICKET_EXPIRY = 5.minutes # CAS Protocol Spec, sec. 3.2.1 (recommended expiry time)

  def conf(key)
    $CONF[key]
  end
  module_function :conf
  
  def login_ticket_expiry
    conf(:login_ticket_expiry) || DEFAULT_LOGIN_TICKET_EXPIRY
  end
  def service_ticket_expiry
    conf(:service_ticket_expiry) || DEFAULT_SERVICE_TICKET_EXPIRY
  end
  module_function :login_ticket_expiry, :service_ticket_expiry
end

require 'casserver/utils'
require 'casserver/models'
require 'casserver/cas'
require 'casserver/views'
require 'casserver/controllers'

# load configuration
$CONF = HashWithIndifferentAccess.new(YAML.load_file(File.dirname(File.expand_path(__FILE__))+"/config.yml"))
begin
  # attempt to instantiate the authenticator
  $AUTH = $CONF[:authenticator].constantize.new
rescue NameError
  # the authenticator class hasn't yet been loaded, so lets try to load it from the casserver/authenticators directory
  auth_rb = $CONF[:authenticator].underscore.gsub('cas_server/', '')
  require 'casserver/'+auth_rb
  $AUTH = $CONF[:authenticator].constantize.new
end

# init the logger
$LOG = CASServer::Utils::Logger.new($CONF[:log][:file] || 'casserver.log')
$LOG.level = "CASServer::Utils::Logger::#{$CONF[:log][:level] || DEBUG}".constantize

# do initialization stuff
def CASServer.create
  CASServer::Models::Base.establish_connection :adapter => 'mysql', :database => 'casserver', :user => 'root', :server => 'localhost'
  CASServer::Models::Base.logger = Logger.new($CONF[:db_log][:file] || 'casserver_db.log')
  CASServer::Models::Base.logger.level = Logger::DEBUG

  CASServer::Models.create_schema
  
  $LOG.info "RubyCAS-Server initialized" 
end


# this gets run if we launch directly (i.e. `ruby casserver.rb` rather than `camping casserver`)
if __FILE__ == $0
  # set up active_record

  CASServer.create
  puts CASServer.run
end 