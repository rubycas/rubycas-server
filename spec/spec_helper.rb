require 'rubygems'
require 'rack/test'
require 'rspec'
#require 'spec/autorun'
#require 'spec/interop/test'
require 'logger'
require 'ostruct'
require 'webmock/rspec'

require 'capybara'
require 'capybara/dsl'
require 'casserver/authenticators/base'
require 'casserver/core_ext.rb'

CASServer::Authenticators.autoload :LDAP, 'casserver/authenticators/ldap.rb'
CASServer::Authenticators.autoload :ActiveDirectoryLDAP, 'casserver/authenticators/active_directory_ldap.rb'
CASServer::Authenticators.autoload :SQL, 'casserver/authenticators/sql.rb'
CASServer::Authenticators.autoload :SQLEncrypted, 'lib/casserver/authenticators/sql_encrypted.rb'
CASServer::Authenticators.autoload :Google, 'casserver/authenticators/google.rb'
CASServer::Authenticators.autoload :ActiveResource, 'casserver/authenticators/active_resource.rb'
CASServer::Authenticators.autoload :Test, 'casserver/authenticators/test.rb'

# require builder because it doesn't pull in the version
# info automatically...
begin
  require 'builder'
  require 'builder/version'
rescue LoadError
  puts "builder not found, testing ActiveRecord 2.3?"
end

if Dir.getwd =~ /\/spec$/
  # Avoid potential weirdness by changing the working directory to the CASServer root
  FileUtils.cd('..')
end

def silence_warnings
  old_verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = old_verbose
end

# Ugly monkeypatch to allow us to test for correct redirection to
# external services.
#
# This will likely break in the future when Capybara or RackTest are upgraded.
class Capybara::RackTest::Browser
  def current_url
    if @redirected_to_external_url
      @redirected_to_external_url
    else
      request.url rescue ""
    end
  end

  def follow_redirects!
    if last_response.redirect? && last_response['Location'] =~ /^http[s]?:/
      @redirected_to_external_url = last_response['Location']
    else
      5.times do
        follow_redirect! if last_response.redirect?
      end
      raise Capybara::InfiniteRedirectError, "redirected more than 5 times, check for infinite redirects." if last_response.redirect?
    end
  end
end

# This called in specs' `before` block.
# Due to the way Sinatra applications are loaded,
# we're forced to delay loading of the server code
# until the start of each test so that certain
# configuraiton options can be changed (e.g. `uri_path`)
def load_server(config_file = 'default_config')
  ENV['CONFIG_FILE'] = File.join(File.dirname(__FILE__),'config',"#{config_file}.yml")

  silence_warnings do
    load File.dirname(__FILE__) + '/../lib/casserver/server.rb'
  end

  # set test environment
  CASServer::Server.set :environment, :test
  CASServer::Server.set :run, false
  CASServer::Server.set :raise_errors, true
  CASServer::Server.set :logging, false

  CASServer::Server.enable(:raise_errors)
  CASServer::Server.disable(:show_exceptions)

  #Capybara.current_driver = :selenium
  Capybara.app = CASServer::Server

  def app
    CASServer::Server
  end
end

# Deletes the sqlite3 database specified in the app's config
# and runs the db:migrate rake tasks to rebuild the database schema.
def reset_spec_database
  raise "Cannot reset the spec database because config[:database][:database] is not defined." unless
    CASServer::Server.config[:database] && CASServer::Server.config[:database][:database]

  FileUtils.rm_f(CASServer::Server.config[:database][:database])

  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.logger.level = Logger::ERROR
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Migrator.migrate("db/migrate")
end

def get_ticket_for(service, username = 'spec_user', password = 'spec_password')
  visit "/login?service=#{CGI.escape(service)}"
  fill_in 'username', :with => username
  fill_in 'password', :with => password
  click_button 'login-submit'

  page.current_url.match(/ticket=(.*)$/)[1]
end
def gem_available?(name)
  if Gem::Specification.methods.include?(:find_all_by_name)
    not Gem::Specification.find_all_by_name(name).empty?
  else
    Gem.available?(name)
  end
end
