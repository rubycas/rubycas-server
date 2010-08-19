require 'rubygems'

$: << File.expand_path(File.dirname(__FILE__)) + '/../vendor/isaac_0.9.1'

require 'casserver/server'

CASServer::Server.run!