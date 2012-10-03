require 'securerandom'

module CASServer
  module CoreExt
    module String
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        # if we're on ruby 1.9 we'll use the built in version
        # this will break if someone trys to use ActiveSupport 3.2+
        # with Ruby 1.8
        def random(length = 29)
          str = "#{Time.now.to_i}r#{SecureRandom.urlsafe_base64(length)}"
          str.gsub!('_','-')
          str[0..(length - 1)]
        end
      end
    end
  end
end
