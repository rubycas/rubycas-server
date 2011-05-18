require 'casserver/authenticators/base'

begin
  require 'active_resource'
rescue LoadError
  require 'rubygems'
  begin
    gem 'activeresource', '~> 3.0.0'
  rescue Gem::LoadError
    $stderr.puts
    $stderr.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    $stderr.puts
    $stderr.puts "To use the ActiveResource authenticator, you must first install the 'activeresource' gem."
    $stderr.puts
    $stderr.puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    exit 1
  end
  require 'active_resource'
end

module CASServer
  module Authenticators

    module Helpers
      class Identity < ActiveResource::Base

      end
    end

    class ActiveResource < Base

      # This is called at server startup.
      # Any class-wide initializiation for the authenticator should be done here.
      # (e.g. establish database connection).
      # You can leave this empty if you don't need to set up anything.
      def self.setup(options)
      end

      # Override this to implement your authentication credential validation.
      # This is called each time the user tries to log in. The credentials hash
      # holds the credentials as entered by the user (generally under :username
      # and :password keys; :service and :request are also included by default)
      #
      # Note that the standard credentials can be read in to instance variables
      # by calling #read_standard_credentials.
      def validate(credentials)
        raise NotImplementedError, "This method must be implemented by a class extending #{self.class}"
      end

    end
  end
end
