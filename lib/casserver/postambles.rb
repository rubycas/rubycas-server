module CASServer
  module Postambles
    
    def webrick
      require 'webrick/httpserver'
      require 'webrick/https'
      require 'camping/webrick'
      
      # TODO: verify the certificate's validity
      # example of how to do this is here: http://pablotron.org/download/ruri-20050331.rb
      
      cert_path = CASServer::Conf.ssl_cert
      key_path = CASServer::Conf.ssl_key || CASServer::Conf.ssl_cert
        # look for the key in the ssl_cert if no ssl_key is specified
      
      webrick_options = {:BindAddress => "0.0.0.0", :Port => CASServer::Conf.port}
      
      unless cert_path.nil? && key_path.nil?
        raise "'#{cert_path}' is not a valid ssl certificate. Your 'ssl_cert' configuration" +
          " setting must be a path to a valid ssl certificate file." unless
            File.exists? cert_path
        
        raise "'#{key_path}' is not a valid ssl private key. Your 'ssl_key' configuration" +
          " setting must be a path to a valid ssl private key file." unless
            File.exists? key_path
        
        cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
        key = OpenSSL::PKey::RSA.new(File.read(key_path))
        
        webrick_options[:SSLEnable] = true
        webrick_options[:SSLVerifyClient] = ::OpenSSL::SSL::VERIFY_NONE
        webrick_options[:SSLCertificate] = cert
        webrick_options[:SSLPrivateKey] = key
      end
      
      begin
        s = WEBrick::HTTPServer.new(webrick_options)
      rescue Errno::EACCES
        puts "\nThe server could not launch. Are you running on a privileged port? (e.g. port 443) If so, you must run the server as root."
        exit 2
      end
      
      CASServer.create
      s.mount "#{CASServer::Conf.uri_path}", WEBrick::CampingHandler, CASServer
      
      puts "\n** CASServer is running at http#{webrick_options[:SSLEnable] ? 's' : ''}://#{Socket.gethostname}:#{CASServer::Conf.port}#{CASServer::Conf.uri_path} and logging to '#{CASServer::Conf.log[:file]}'\n\n"
    
      # This lets Ctrl+C shut down your server
      trap(:INT) do
        s.shutdown
      end
      trap(:TERM) do
        s.shutdown
      end
    
      if $DAEMONIZE
        WEBrick::Daemon.start do
          write_pid_file if $PID_FILE
          s.start
          clear_pid_file
        end
      else
        s.start
      end
    end
    
    
    
    def mongrel
      require 'rubygems'
      require 'mongrel/camping'
      
      if $DAEMONIZE
        # check if log and pid are writable before daemonizing, otherwise we won't be able to notify
        # the user if we run into trouble later (since once daemonized, we can't write to stdout/stderr)
        check_pid_writable if $PID_FILE
        check_log_writable
      end
      
      CASServer.create
      
      puts "\n** CASServer is starting. Look in '#{CASServer::Conf.log[:file]}' for further notices."
      
      settings = {:host => "0.0.0.0", :log_file => CASServer::Conf.log[:file], :cwd => $CASSERVER_HOME}
      
      # need to close all IOs before daemonizing
      $LOG.close if $DAEMONIZE
      
      begin
        config = Mongrel::Configurator.new settings  do
          daemonize :log_file => CASServer::Conf.log[:file], :cwd => $CASSERVER_HOME if $DAEMONIZE
          
          listener :port => CASServer::Conf.port do
            uri CASServer::Conf.uri_path, :handler => Mongrel::Camping::CampingHandler.new(CASServer)
            setup_signals
          end
        end
      rescue Errno::EADDRINUSE
        exit 1
      end
      
      config.run
      
      CASServer.init_logger
      CASServer.init_db_logger
      
      if $DAEMONIZE && $PID_FILE
        write_pid_file
        unless File.exists? $PID_FILE
          $LOG.error "CASServer could not start because pid file '#{$PID_FILE}' could not be created."
          exit 1
        end
      end
      
      puts "\n** CASServer is running at http://localhost:#{CASServer::Conf.port}#{CASServer::Conf.uri_path} and logging to '#{CASServer::Conf.log[:file]}'"
      config.join

      clear_pid_file

      puts "\n** CASServer is stopped (#{Time.now})"
    end
    
    
    def fastcgi
      require 'camping/fastcgi'
      Dir.chdir('/srv/www/camping/casserver/')
      
      CASServer.create
      Camping::FastCGI.start(CASServer)
    end
    
    
    def cgi
      CASServer.create
      puts CASServer.run
    end
    
    private
    def check_log_writable
      log_file = CASServer::Conf.log['file']
      begin
        f = open(log_file, 'w')
      rescue
        $stderr.puts "Couldn't write to log file at '#{log_file}' (#{$!})."
        exit 1
      end
      f.close
    end
    
    def check_pid_writable
      $LOG.debug "Checking if pid file '#{$PID_FILE}' is writable"
      begin        
        f = open($PID_FILE, 'w')
      rescue
        $stderr.puts "Couldn't write to log at '#{$PID_FILE}' (#{$!})."
        exit 1
      end
      f.close
    end
    
    def write_pid_file
      $LOG.debug "Writing pid '#{Process.pid}' to pid file '#{$PID_FILE}'"
      open($PID_FILE, "w") { |file| file.write(Process.pid) }
    end
    
    def clear_pid_file
      if $PID_FILE && File.exists?($PID_FILE)
        $LOG.debug "Clearing pid file '#{$PID_FILE}'"
        File.unlink $PID_FILE
      end
    end
  
  end
end
