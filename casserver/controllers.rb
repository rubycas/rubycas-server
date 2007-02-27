# The #.#.# comments (e.g. "2.1.3") refer to section numbers in the CAS protocol spec
# under http://www.ja-sig.org/products/cas/overview/protocol/index.html

module CASServer::Controllers

  # 2.1
  class Login < R '/', '/login'
    include CASServer::CAS
    
    # 2.1.1
    def get
      # make sure there's no caching
      headers['Pragma'] = 'no-cache'
      headers['Cache-Control'] = 'no-store'
      headers['Expires'] = (Time.now - 1.year).rfc2822
      
      # optional params
      @service = @input['service']
      @renew = @input['renew']
      @gateway = @input['gateway']
      
      if !@renew && tgc = @cookies[:tgt]
        tgt, error = validate_ticket_granting_ticket(tgc)
        if tgt && !error
          st = generate_service_ticket(@service, tgt.username)
          service_with_ticket = service_uri_with_ticket(@service, st)
          $LOG.info("User '#{tgt.username}' authenticated based on ticket granting cookie. Redirecting to service '#{@service}'.")
          return redirect(service_with_ticket, :status => 303) # response code 303 means "See Other" (see Appendix B in CAS Protocol spec)
        end
        
      end
      
      lt = generate_login_ticket
      
      $LOG.debug("Rendering login form with lt: #{lt}, service: #{@service}, renew: #{@renew}, gateway: #{@gateway}")
      
      @lt = lt.ticket
      
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
      
      if error = validate_login_ticket(@lt)
        @message = {:type => 'mistake', :message => error}
        return render(:login)
      end
      
      $AUTH.configure(CASServer::Conf.authenticator)
      
      $LOG.debug("Logging in with username: #{@username}, lt: #{@lt}, service: #{@service}, auth: #{$AUTH}")
      
      if $AUTH.validate(:username => @username, :password => @password)
        $LOG.info("Credentials for username '#{@username}' successfully validated")
        
        # 3.6 (ticket-granting cookie)
        tgt = generate_ticket_granting_ticket(@username)
        @cookies[:tgt] = tgt.to_s
        $LOG.debug("Ticket granting cookie '#{@cookies[:tgt]}' granted to '#{@username}'")
        
        @st = generate_service_ticket(@service, @username)        

        service_with_ticket = service_uri_with_ticket(@service, @st)
        
        if !@service.blank?
          $LOG.info("Redirecting authenticated user '#{@username}' to service '#{@service}'")
          return redirect(service_with_ticket, :status => 303) # response code 303 means "See Other" (see Appendix B in CAS Protocol spec)
        else
          $LOG.info("Successfully authenticated user '#{@username}'. No service param was given so we will not redirect.")
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
    include CASServer::CAS
    
    # 2.3.1
    def get
      @url = @input['url']
      
      @message = {:type => 'confirmation', :message => "You have successfully logged out."}
      
      render :login
    end
  end

  # 2.4
  class Validate < R '/validate'
    include CASServer::CAS
  
    # 2.4.1
    def get
      # required
      @service = @input['service']
      @ticket = @input['ticket']
      # optional
      @renew = @input['renew']
      
      st, @error = validate_service_ticket(@service, @ticket)      
      @success = st && !@error
      
      @username = st.username if @success
      
      render :validate
    end
  end
  
  # 2.5
  class ServiceValidate < R '/serviceValidate'
    include CASServer::CAS
  
    # 2.5.1
    def get
      # required
      @service = @input['service']
      @ticket = @input['ticket']
      # optional
      @pgt_url = @input['pgtUrl']
      @renew = @input['renew']
      
      st, @error = validate_service_ticket(@service, @ticket)      
      @success = st && !@error
      
      if @success
        @username = st.username  
        if @pgt_url
          pgt = generate_proxy_granting_ticket(@pgt_url, st)
          @pgtiou = pgt.iou if pgt
        end
      end
      
      render :service_validate
    end
  end
  
  # 2.6
  class ProxyValidate < R '/proxyValidate'
    include CASServer::CAS
  
    # 2.6.1
    def get
      # required
      @service = @input['service']
      @ticket = @input['ticket']
      # optional
      @pgt_url = @input['pgtUrl']
      @renew = @input['renew']
      
      @proxies = []
      
      t, @error = validate_proxy_ticket(@service, @ticket)      
      @success = t && !@error
      
      if @success
        @username = t.username
        
        if t.kind_of? CASServer::Models::ProxyTicket
          @proxies << t.proxy_granting_ticket.service_ticket.service
        end
          
        if @pgt_url
          pgt = generate_proxy_granting_ticket(@pgt_url, t)
          @pgtiou = pgt.iou if pgt
        end
      end

      render :proxy_validate
    end
  end
  
  class Proxy < R '/proxy'
    include CASServer::CAS
  
    # 2.7
    def get
      # required
      @ticket = @input['pgt']
      @target_service = @input['targetService']
      
      pgt, @error = validate_proxy_granting_ticket(@ticket, @target_service)
      @success = pgt && !@error
      
      if @success
        @pt = generate_proxy_ticket(@target_service, pgt)
      end
      
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