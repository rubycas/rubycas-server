require 'sinatra/base'
require 'sinatra/r18n'
require 'sinatra/config_file'
require 'logger'

module CASServer
  class Base < Sinatra::Base
    register Sinatra::R18n
    register Sinatra::ConfigFile

    R18n::I18n.default = 'en'
    R18n.default_places { File.join(root,'..','..','locales') }

    config_file File.join("..","..",ENV['CONFIG_FILE'] || "config/rubycas.yml")
    # default configuration
    set :maximum_unused_login_ticket_lifetime, 6.minutes unless settings.respond_to? "maximum_unused_login_ticket_lifetime"
    set :maximum_unused_service_ticket_lifetime, 5.minutes unless settings.respond_to? "maximum_unused_service_ticket_lifetime"
    set :maximum_session_lifetime, 2.days unless settings.respond_to? "maximum_session_lifetime"
    set :uri_path,  "" unless settings.respond_to? "uri_path"
    set :server, 'webrick' unless settings.respond_to? "server"
    set :static, true
    set :public_folder, File.expand_path(settings.public_folder)
    set :log_level, 1 unless settings.respond_to? "log_level"
    set :log_file, "log/casserver.log" unless settings.respond_to? "log_file"
    set :db_log_file, "log/database.log" unless settings.respond_to? "db_log_file"
    set :db_log_level, 1 unless settings.respond_to? "db_log_level"
    set :disable_auto_migrations, false unless settings.respond_to? "disable_auto_migrations"
    set :template_engine, nil unless settings.respond_to? "template_engine"
    set :downcase_username, false unless settings.respond_to? "downcase_username"
    set :ssl_cert, nil unless settings.respond_to? "ssl_cert"
    set :ssl_key, nil unless settings.respond_to? "ssl_key"

    def self.initialize_database
      begin
        unless settings.disable_auto_migrations
          ActiveRecord::Base.establish_connection(settings.database)
          $LOG.info "Running migrations to make sure your database schema is up to date..."
          prev_db_log = ActiveRecord::Base.logger
          ActiveRecord::Base.logger = Logger.new(STDOUT)
          ActiveRecord::Migration.verbose = true
          ActiveRecord::Migrator.migrate(File.dirname(__FILE__) + "/../../db/migrate")
          ActiveRecord::Base.logger = prev_db_log
          $LOG.info "Your database is now up to date."
        end
        ActiveRecord::Base.establish_connection(settings.database)
      rescue => e
        $LOG.error e
        raise "Problem to establish connection to database. Check if is correct configured"
      end
    end

    configure do
      $LOG ||= Logger.new(settings.log_file)
      $LOG.level = settings.log_level || 1
      ActiveRecord::Base.logger = Logger.new(settings.db_log_file)
      ActiveRecord::Base.logger.level = settings.db_log_level || 1

      initialize_database

      # setup all authenticators
      settings.authenticators.each_with_index do |authenticator, index|
        auth_klass = authenticator["class"].constantize
        auth_klass.setup(HashWithIndifferentAccess.new(authenticator.merge('auth_index' => index))) if auth_klass.respond_to?(:setup)
      end
    end

  end
end
