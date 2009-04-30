require 'rubygems'
require 'rack'

$APP_NAME = 'rubycas-server'
$APP_ROOT = File.dirname(File.expand_path(__FILE__))

if File.exists?("#{$APP_ROOT}/tmp/debug.txt")
  require 'ruby-debug'
  Debugger.wait_connection = true
  Debugger.start_remote
end

$: << $APP_ROOT + "/lib"

require 'casserver/load_picnic'
require 'picnic'
require 'casserver'

CASServer.create

if $CONF.uri_path
	map($CONF.uri_path) do
    # FIXME: this probably isn't the smartest way of remapping the themes dir to uri_path/themes
    use Rack::Static, $CONF[:static] if $CONF[:static]
		run CASServer
	end
else
	run CASServer
end
