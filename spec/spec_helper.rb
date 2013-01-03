require 'rubygems'
require 'rack/test'
require 'rspec'
require 'logger'
require 'ostruct'
require 'webmock/rspec'
require 'capybara'
require 'capybara/dsl'

def load_server(config_file = "spec/config/default_config.yml" )
  ENV["CONFIG_FILE"] = config_file

  # We need reload whole sinatra server to make sure
  # that he will use proper config file.
  Kernel.load File.dirname(__FILE__) + '/../lib/casserver.rb'
  Kernel.load File.dirname(__FILE__) + '/../lib/casserver/base.rb'
  Kernel.load File.dirname(__FILE__) + '/../lib/casserver/server.rb'

  def app
    CASServer::Server
  end
  # set test environment
  app.set :environment, :test
  app.set :run, false
  app.set :raise_errors, true
  app.set :logging, false

  app.enable(:raise_errors)
  app.disable(:show_exceptions)

  Capybara.app = app
end

# Deletes the sqlite3 database specified in the app's config
# and runs the db:migrate rake tasks to rebuild the database schema.
def reset_spec_database
  app.settings.database && app.settings.database[:database]
  ActiveRecord::Base.establish_connection(app.settings.database)
  case app.settings.database[:adapter]
   when /sqlite/
     require 'pathname'
     path = Pathname.new(app.settings.database[:database])
     file = path.absolute? ? path.to_s : File.join(app.settings.root, '..', '..', path)
     FileUtils.rm(file) if File.exist?(file)
   else
     ActiveRecord::Base.connection.drop_database app.settings.database[:database]
  end

  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.logger.level = Logger::ERROR
  ActiveRecord::Migration.verbose = false
  ActiveRecord::Migrator.migrate("db/migrate")
end

def gem_available?(name)
  if Gem::Specification.methods.include?(:find_all_by_name)
    not Gem::Specification.find_all_by_name(name).empty?
  else
    Gem.available?(name)
  end
end
