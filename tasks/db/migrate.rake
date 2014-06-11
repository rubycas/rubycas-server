namespace :db do
  desc "bring your CAS server database schema up to date (options CONFIG_FILE=/path/to/config.yml)"
  task :migrate do |t|
    $:.unshift File.dirname(__FILE__) + "/../../lib"

    require 'casserver/authenticators/base'
    require 'casserver/server'

    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = Logger::ERROR
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("db/migrate")
  end
end
