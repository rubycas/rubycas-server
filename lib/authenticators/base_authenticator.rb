module CASServer
  module Authenticators
    class Base
      attr_accessor :options
    
      def validate(credentials)
        raise NotImplementedError, "This method must be implemented by a class extending #{self.class}"
      end
      
      def configure(options)
        raise ArgumentError, "options must be a Hash" unless options.kind_of? Hash
        
        symbolize_hash(options)
        
        # don't override options that have already been set... this is done so that you can
        # hard-code or dynamically set some options in your authenticator class
        @options = {} unless @options
        options.each do |k,v|
          @options[k] = v if @options[k].nil?
        end
      end
      
      protected
      def read_standard_credentials(credentials)
        symbolize_hash(credentials)
        @username = credentials[:username]
        @password = credentials[:password]
      end
      
      private
      # Turns all of the String keys in a Hash into Symbols.
      # We use this to make reading parameters from yaml easier.
      def symbolize_hash(hash)
        hash.each do |k,v|
          symbolize_hash(v) if v.kind_of? Hash
          if k.kind_of? String
            hash[k.to_sym] = v
            hash.delete k
          end
        end
      end
    end
  end
end