require 'active_support'
require 'active_support/hash_with_indifferent_access'
require 'active_support/core_ext'

module CASServer
  module Authenticators
    class Base
      attr_accessor :options
      attr_reader :username # make this accessible so that we can pick up any
                            # transformations done within the authenticator

      # This is called at server startup.
      # Any class-wide initializiation for the authenticator should be done here.
      # (e.g. establish database connection).
      # You can leave this empty if you don't need to set up anything.
      def self.setup(options)
      end

      # This is called prior to #validate (i.e. each time the user tries to log in).
      # Any per-instance initialization for the authenticator should be done here.
      #
      # By default this makes the authenticator options hash available for #validate
      # under @options and initializes @extra_attributes to an empty hash.
      def configure(options)
        raise ArgumentError, "options must be a HashWithIndifferentAccess" unless options.kind_of? HashWithIndifferentAccess
        @options = options.dup
        @extra_attributes = {}
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

      def extra_attributes
        @extra_attributes
      end

      protected
      def read_standard_credentials(credentials)
        @username = credentials[:username]
        @password = credentials[:password]
        @service = credentials[:service]
        @request = credentials[:request]
      end

      def extra_attributes_to_extract
        if @options[:extra_attributes].kind_of? Array
          attrs = @options[:extra_attributes]
        elsif @options[:extra_attributes].kind_of? String
          attrs = @options[:extra_attributes].split(',').collect{|col| col.strip}
        else
          $LOG.error("Can't figure out attribute list from #{@options[:extra_attributes].inspect}. This must be an Array of column names or a comma-separated list.")
          attrs = []
        end

        $LOG.debug("#{self.class.name} will try to extract the following extra_attributes: #{attrs.inspect}")
        return attrs
      end
    end
  end

  class AuthenticatorError < Exception
  end
end
