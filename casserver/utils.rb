# Misc utility function used throughout by the RubyCAS-server.
module CASServer
  module Utils
    def random_string
      "#{Time.now.to_i}r%X" % rand(10**32)
    end
    module_function :random_string
    
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