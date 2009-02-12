require 'rubygems'
require 'rack'

$APP_NAME = 'rubycas-server'
$APP_ROOT = File.dirname(File.expand_path(__FILE__))
$: << $APP_ROOT + "/lib"

require File.dirname(File.expand_path(__FILE__)) + '/lib/casserver'

$LOG = Logger.new("casserver.log")
$LOG.level = Logger::DEBUG

CASServer.create

if $CONF.uri_path
	map($CONF.uri_path) do
		run CASServer
	end
else
	run CASServer
end
