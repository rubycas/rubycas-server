module CASServer; end

$: << File.expand_path(File.dirname(__FILE__) + '/casserver')
$: << File.expand_path(File.dirname(__FILE__) + '/../vendor/isaac_0.9.1')

require 'active_record'
require 'active_support'
require 'sinatra/base'
require 'haml'
require 'logger'
$LOG = Logger.new(STDOUT)

require 'server'

