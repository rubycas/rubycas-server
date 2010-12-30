module CASServer; end

require 'active_record'
require 'active_support'
require 'sinatra/base'
require 'logger'
$LOG = Logger.new(STDOUT)

require 'casserver/server'

