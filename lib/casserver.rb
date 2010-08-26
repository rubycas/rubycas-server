require 'rubygems'
require 'bundler'
Bundler.setup

$: << File.dirname(__FILE__)

require 'casserver/server'

CASServer::Server.run!