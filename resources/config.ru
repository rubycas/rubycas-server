# This is the Rackup initialization script for running RubyCAS-Server under Passenger/Rack.
#
# This file doesn't really have anything to do with your server's "configuration",
# and you almost certainly don't need to modify it. Instead, a config file should
# have been created for you (probably under /etc/rubycas-server/config.yml) -- this
# is the file you'll want to modify. If for some reason the configuration file
# was not created for you, have a look at the config.example.yml template and
# go from there.

require 'rubygems'
require 'rack'

$APP_NAME = 'rubycas-server'
$APP_ROOT = ::File.dirname(::File.expand_path(__FILE__))

if ::File.exist?("#{$APP_ROOT}/tmp/debug.txt")
  require 'ruby-debug'
  Debugger.wait_connection = true
  Debugger.start_remote
end

$:.unshift $APP_ROOT + "/lib"

require 'casserver/load_picnic'
require 'picnic'
require 'casserver'

CASServer.create
hack = lambda{ |env|
  ActiveRecord::Base.verify_active_connections!
  CASServer.call(env)
}

if $CONF.uri_path
  map($CONF.uri_path) do
    # FIXME: this probably isn't the smartest way of remapping the themes dir to uri_path/themes
    use Rack::Static, $CONF[:static] if $CONF[:static]
    run hack
  end
else
  run hack
end
