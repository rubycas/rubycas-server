require 'securerandom'

module CASServer
  module CoreExt
    module String
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def random(length = 29)
          str = "#{Time.now.to_i}r#{SecureRandom.base64(length)}"
          str[0..(length - 1)]
        end
      end
    end
  end
end
