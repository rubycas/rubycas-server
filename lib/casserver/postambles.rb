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
      
      raise "'#{cert_path}' is not a valid ssl certificate. Your 'ssl_cert' configuration" +
        " setting must be a path to a valid ssl certificate file." unless
          File.exists? cert_path
      
      raise "'#{key_path}' is not a valid ssl private key. Your 'ssl_key' configuration" +
        " setting must be a path to a valid ssl private key file." unless
          File.exists? key_path
      
      cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
      key = OpenSSL::PKey::RSA.new(File.read(key_path))
      
      begin
        s = WEBrick::HTTPServer.new(
          :BindAddress => "0.0.0.0",
          :Port => CASServer::Conf.port,
          :SSLEnable => true,
          :SSLVerifyClient => ::OpenSSL::SSL::VERIFY_NONE,
          :SSLCertificate => cert,
          :SSLPrivateKey => key
        )
      rescue Errno::EACCES
        puts "\nThe server could not launch. Are you running on a privileged port? (e.g. port 443) If so, you must run the server as root."
        exit 2
      end
      
      CASServer.create
      s.mount "#{CASServer::Conf.uri_path}", WEBrick::CampingHandler, CASServer
      
      puts "\n** CASServer is running at http://localhost:#{CASServer::Conf.port}#{CASServer::Conf.uri_path} and logging to '#{CASServer::Conf.log[:file]}'\n\n"
    
      # This lets Ctrl+C shut down your server
      trap(:INT) do
        s.shutdown
      end
    
      if $DAEMONIZE
        WEBrick::Daemon.start {s.start}
      else
        s.start
      end
    end
    
    
    
    def mongrel
      require 'rubygems'
      require 'mongrel/camping'
      
      # camping has fixes for mongrel currently only availabe in SVN
      # ... you can install camping from svn (1.5.180) by running: 
      #     gem install camping --source code.whytheluckystiff.net
      require_gem 'camping', '~> 1.5.180'
      
      CASServer.create    
      
      puts "\n** CASServer is starting. Look in '#{CASServer::Conf.log[:file]}' for further notices."
      
      settings = {:host => "0.0.0.0", :log_file => CASServer::Conf.log[:file], :cwd => $CASSERVER_HOME}
      
      # need to close all IOs if we daemonize
      $LOG.close
      
      config = Mongrel::Configurator.new settings  do
        daemonize :log_file => CASServer::Conf.log[:file], :cwd => $CASSERVER_HOME if $DAEMONIZE
        
        listener :port => CASServer::Conf.port do
          uri CASServer::Conf.uri_path, :handler => Mongrel::Camping::CampingHandler.new(CASServer)
          setup_signals
        end
      end
      
      config.run
      
      CASServer.init_logger
      CASServer.init_db_logger
      
      puts "\n** CASServer is running at http://localhost:#{CASServer::Conf.port}#{CASServer::Conf.uri_path} and logging to '#{CASServer::Conf.log[:file]}'"
      config.join
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
  
  end
end
