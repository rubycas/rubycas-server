require 'test/unit'

require 'logger'

require 'rubygems'
require 'active_support'

$: << File.dirname(__FILE__)+'/../lib'

$LOG = Logger.new('/dev/null')

module CASServer
  module Models
  end
end
