# Misc utility function used throughout by the RubyCAS-server.
module CASServer
  module Utils
    def random_string(max_length = 29)
      rg =  Crypt::ISAAC.new
      max = 4294619050
      r = "#{Time.now.to_i}r%X%X%X%X%X%X%X%X" % 
        [rg.rand(max), rg.rand(max), rg.rand(max), rg.rand(max), 
         rg.rand(max), rg.rand(max), rg.rand(max), rg.rand(max)]
      r[0..max_length-1]
    end
    module_function :random_string
      
    def log_controller_action(controller, params)
      $LOG << "\n"
      
      /`(.*)'/.match(caller[1])
      method = $~[1]
      
      if params.respond_to? :dup
        params2 = params.dup
        params2['password'] = '******' if params2['password']
      else
        params2 = params
      end
      $LOG.debug("Processing #{controller}::#{method} #{params2.inspect}")
    end
    module_function :log_controller_action
  end
end