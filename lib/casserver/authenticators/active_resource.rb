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

        # define method_name accessor
        cattr_accessor(:method_name)
        self.method_name = :authenticate

        def self.method_type
          @@method_type ||= :post
        end

        def self.method_type= type
          methods = [:get, :post, :put, :delete]
          raise ArgumentError, "Method type should be one of #{methods.map { |m| m.to_s.upcase }.join(', ')}" unless methods.include? type.to_sym
          @@method_type = type
        end

        # Autenticate an identity using the given method
        # @param [Hash] credentials
        def self.authenticate(credentials = {})
          response = send(method_type, method_name, credentials)
          new.from_authentication_data(response)
        end

        # Used to load object attributes from the given response
        def from_authentication_data response
          load_attributes_from_response(response)
        end
      end
    end

    class ActiveResource < Base

      # This is called at server startup.
      # Any class-wide initializiation for the authenticator should be done here.
      # (e.g. establish database connection).
      # You can leave this empty if you don't need to set up anything.
      def self.setup(options)
        raise AuthenticatorError, 'You must define at least site option' unless options[:site]
        # apply options to active resource object
        options.each do |method, arg|
          Helpers::Identity.send "#{method}=", arg if Helpers::Identity.respond_to? "#{method}="
        end
        $LOG.info "ActiveResource configuration loaded"
      end

      # Override this to implement your authentication credential validation.
      # This is called each time the user tries to log in. The credentials hash
      # holds the credentials as entered by the user (generally under :username
      # and :password keys; :service and :request are also included by default)
      #
      # Note that the standard credentials can be read in to instance variables
      # by calling #read_standard_credentials.
      def validate(credentials)
        begin
          $LOG.debug("Starting Active Resource authentication")
          result = Helpers::Identity.authenticate(credentials.except(:request))
          extract_extra_attributes(result) if result
          !!result
        rescue ::ActiveResource::ConnectionError => e
          if e.response.blank? # band-aid for ARes 2.3.x -- craps out if to_s is called without a response
            e = e.class.to_s
          end
          $LOG.warn("Error during authentication: #{e}")
          false
        end
      end

      private

      def extract_extra_attributes(resource)
        @extra_attributes = {}
        $LOG.debug("Parsing extra attributes")
        if @options[:extra_attributes]
          extra_attributes_to_extract.each do |attr|
            @extra_attributes[attr] = resource.send(attr).to_s
          end
        else
          @extra_attributes = resource.attributes
        end
        # do filtering
        extra_attributes_to_filter.each do |attr|
          @extra_attributes.delete(attr)
        end
      end

      # extract attributes to filter from the given configuration
      def extra_attributes_to_filter
        # default value if not set
        return ['password'] unless @options[:filter_attributes]
        # parse option value
        if @options[:filter_attributes].kind_of? Array
          attrs = @options[:filter_attributes]
        elsif @options[:filter_attributes].kind_of? String
          attrs = @options[:filter_attributes].split(',').collect { |col| col.strip }
        else
          $LOG.error("Can't figure out attribute list from #{@options[:filter_attributes].inspect}. This must be an Array of column names or a comma-separated list.")
          attrs = []
        end
        attrs
      end
    end
  end
end
