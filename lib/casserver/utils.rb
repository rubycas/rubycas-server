# Misc utility function used throughout by the RubyCAS-Server.
module CASServer
  module Utils
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
