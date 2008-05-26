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
      
      protected
      def read_standard_credentials(credentials)
        @username = credentials[:username]
        @password = credentials[:password]
        @service = credentials[:service]
        @request = credentials[:request]
      end
    end
  end
  
  class AuthenticatorError < Exception
  end
end