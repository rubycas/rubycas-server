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
      @lt = LoginTicket.new
      @lt.ticket = "LT-" + CASServer::Utils.random_string
      @lt.client_hostname = env['REMOTE_HOST'] || env['REMOTE_ADDR']
      @lt.save!
      
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
        
        # 3.6 (ticket-granting cookie)
        @cookies[:tgc] = "TGC-" + CASServer::Utils.random_string
        $LOG.debug("Ticket granting cookie '#{@cookies[:tgc]}' granted to '#{@username}'")
        
        # 3.1 (service ticket)
        @st = ServiceTicket.new
        @st.ticket = "ST-" + CASServer::Utils.random_string
        @st.service = @service
        @st.username = @username
        @st.client_hostname = env['REMOTE_HOST'] || env['REMOTE_ADDR']
        @st.save!
        
        service_uri = URI.parse(@service)
        if service_uri.query
          service_with_ticket = @service + "&ticket=" + @st.ticket
        else
          service_with_ticket = @service + "?ticket=" + @st.ticket
        end
        
        if !@service.blank?
          $LOG.info("Redirecting authenticated user '#{@username}' to service '#{@service}'")
          return redirect(service_with_ticket, :status => 303) # response code 303 means "See Other" (see Appendix B in CAS Protocol spec)
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
      
      @success = false
      
      if @service.nil? or @ticket.nil?
        @error = Error.new("INVALID_REQUEST", "Ticket or service parameter was missing in the request.")
      elsif st = ServiceTicket.find_by_ticket(@ticket)
        if st.service == @service
          @success = true
        else
          @error = Error.new("INVALID_SERVICE", "The ticket #{@ticket} is valid,"+
            " but the service specified does not match the service associated with this ticket.")
        end
      else
        @error = Error.new("INVALID_TICKET", "Ticket #{@ticket} not recognized.")
      end
      
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