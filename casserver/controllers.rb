# The #.#.# comments (e.g. "2.1.3") refer to section numbers in the CAS protocol spec
# under http://www.ja-sig.org/products/cas/overview/protocol/index.html

module CASServer::Controllers

  # 2.1
  class Login < R '/', '/login'
    # 2.1.1
    def get      
      # optional
      @service = @input['service']
      @renew = @input['renew']
      @gateway = @input['gateway']
      
      # 3.5 (login ticket)
      @lt = "LT-" + CASServer::Util.random_string
      
      $LOG.debug("Rendering login form with lt: #{@lt}, service: #{@service}, renew: #{@renew}, gateway: #{@gateway}")
      
      render :login
    end
    
    # 2.2
    def post
      # 2.2.1 (optional)
      @service = @input['service']
      @warn = @input['warn']
      
      # 2.2.2 (required)
      @username = @input['username']
      @password = @input['password']
      @lt = @input['lt']
      
      $AUTH.configure($CONF)
      
      $LOG.debug("Logging in with username: #{@username}, lt: #{@lt}, service: #{@service}, auth: #{$AUTH}")
      
      if $AUTH.validate(:username => @username, :password => @password)
        $LOG.info("Credentials for username '#{@username}' successfully validated")
        
        @cookies[:tgc] = "TGC-" + CASServer::Util.random_string
        $LOG.debug("Ticket granting cookie '#{@cookies[:tgc]}' granted to '#{@username}'")
        
        if !@service.blank?
          $LOG.info("Redirecting authenticated user '#{@username}' to service '#{@service}'")
          return redirect(@service)
        else
          $LOG.info("Successfully authenticated user #{@username}. No service param was given so we will not redirect.")
          @message = {:type => 'confirmation', :message => "You have successfully logged in."}
          render :login
        end
      else
        $LOG.warn("Invalid credentials given for user '#{@username}'")
        @message = {:type => 'mistake', :message => "Incorrect username or password."}
        render :login
      end
    end
  end
  
  # 2.3
  class Logout < R '/logout'
    # 2.3.1
    def get
      @url = @input['url']
      
      render :logout
    end
  end

  # 2.4
  class Validate < R '/validate'
    # 2.4.1
    def get
      # required
      @service = @input['service']
      @ticket = @input['ticket']
      # optional
      @renew = @input['renew']
      
      render :validate
    end
  end
  
  # 2.5
  class ServiceValidate < R '/serviceValidate'
    # 2.5.1
    def get
      # required
      @service = @input['service']
      @ticket = @input['ticket']
      # optional
      @pgt_url = @input['pgtUrl']
      @renew = @input['renew']
      
      render :service_validate
    end
  end
  
  # 2.6
  class ProxyValidate < R '/proxyValidate'
    # 2.6.1
    def get
      # required
      @service = @input['service']
      @ticket = @input['ticket']
      # optional
      @pgt_url = @input['pgtUrl']
      @renew = @input['renew']
      
      render :proxy_validate
    end
  end
  
  class Proxy < R '/proxy'
    # 2.7
    def get
      # required
      @pgt = @input['pgt']
      @target_service = @input['targetService']
      
      render :proxy
    end
  end
  
  class Static < R '/static/(.+)'         
    MIME_TYPES = {'.css' => 'text/css', '.js' => 'text/javascript', 
                  '.jpg' => 'image/jpeg'}
    PATH = File.expand_path(File.dirname(__FILE__))+'/..'

    def get(path)
      @headers['Content-Type'] = MIME_TYPES[path[/\.\w+$/, 0]] || "text/plain"
      unless path.include? ".." # prevent directory traversal attacks
        @headers['X-Sendfile'] = "#{PATH}/static/#{path}"
      else
        @status = "403"
        "403 - Invalid path"
      end
    end
  end
end