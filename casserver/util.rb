# Misc utility function used throughout by the RubyCAS-server.
module CASServer
  module Util
    def rand_string
      "#{Time.now.to_i}r%X" % rand(99999999)
    end
    module_function :random_string
  end
end