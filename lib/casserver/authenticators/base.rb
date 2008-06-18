module CASServer
  module Authenticators
    class Base
      attr_accessor :options
      attr_reader :username # make this accessible so that we can pick up any 
                            # transformations done within the authenticator
    
      def validate(credentials)
        raise NotImplementedError, "This method must be implemented by a class extending #{self.class}"
      end
      
      def configure(options)
        raise ArgumentError, "options must be a HashWithIndifferentAccess" unless options.kind_of? HashWithIndifferentAccess
        @options = options.dup
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
          $LOG.error("Can't figure out attribute list from #{@options[:extra_attributes].inspect}. This must be an Aarray of column names or a comma-separated list.")
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