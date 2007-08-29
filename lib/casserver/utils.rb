# Misc utility function used throughout by the RubyCAS-server.
module CASServer
  module Utils
    def random_string
      "#{Time.now.to_i}r%X" % rand(10**32)
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
    
    class Logger < ::Logger
      def initialize(logdev, shift_age = 0, shift_size = 1048576)
        begin
          super
        rescue Exception
          puts "WARNING: Couldn't create Logger with output '#{logdev}'. Logger output will be redirected to STDOUT."
          super(STDOUT, shift_age, shift_size)
        end
      end
    
      def format_message(severity, datetime, progrname, msg)
        (@formatter || @default_formatter).call(severity, datetime, progname, msg)
      end
    end
  end
  
  class LogFormatter < ::Logger::Formatter
    Format = "[%s#%d] %5s -- %s: %s\n"
    
    def call(severity, time, progname, msg)
      Format % [format_datetime(time), $$, severity, progname,
        msg2str(msg)]
    end
  end
end