module CASServer; end

require 'active_record'
require 'active_support'
require 'sinatra/base'
require 'builder' # for XML views
require 'logger'
$LOG = Logger.new(STDOUT)

require 'casserver/server'

