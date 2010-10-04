require 'rubygems'
require 'sinatra'
require 'rack/test'
require 'spec'
require 'spec/autorun'
require 'spec/interop/test'
require 'logger'

# set test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

def silence_warnings
  old_verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = old_verbose
end

# this called in specs' `before` block
# ... due to the way Sinatra applications are loaded,
#     we're forced to delay loading of the server code
#     until the start of each test so that certain 
#     configuraiton options can be changed (e.g. `uri_path`)
def load_server(config_file)
  ENV['CONFIG_FILE'] = config_file
  
  silence_warnings do
    load File.dirname(__FILE__) + '/../lib/casserver/server.rb'
  end
  
  CASServer::Server.enable(:raise_errors)
  CASServer::Server.disable(:show_exceptions)

  #Capybara.current_driver = :selenium
  Capybara.app = CASServer::Server
end