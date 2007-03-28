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
      
      if tgc = @cookies[:tgt]
        tgt, tgt_error = validate_ticket_granting_ticket(tgc)
      end
      
      if tgt and !tgt_error
        @message = {:type => 'notice', :message => %{You are currently logged in as "#{tgt.username}". If you are not "#{tgt.username}", please log in below.}}
      end
      
      if @service && !@renew && tgt && !tgt_error
        st = generate_service_ticket(@service, tgt.username)
        service_with_ticket = service_uri_with_ticket(@service, st)
        $LOG.info("User '#{tgt.username}' authenticated based on ticket granting cookie. Redirecting to service '#{@service}'.")
        return redirect(service_with_ticket, :status => 303) # response code 303 means "See Other" (see Appendix B in CAS Protocol spec)
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
        # generate another login ticket to allow for re-submitting the form
        @lt = generate_login_ticket.ticket
        return render(:login)
      end
      
      # generate another login ticket to allow for re-submitting the form after a post
      @lt = generate_login_ticket.ticket
      
      $AUTH.configure(CASServer::Conf.authenticator)
      
      $LOG.debug("Logging in with username: #{@username}, lt: #{@lt}, service: #{@service}, auth: #{$AUTH}")
      
      begin
        credentials_are_valid = $AUTH.validate(:username => @username, :password => @password)
      rescue AuthenticatorError => e
        $LOG.error(e)
        @message = {:type => 'mistake', :message => e.to_s}
        render :login and return
      end
      
      if credentials_are_valid
        $LOG.info("Credentials for username '#{@username}' successfully validated")
        
        # 3.6 (ticket-granting cookie)
        tgt = generate_ticket_granting_ticket(@username)
        @cookies[:tgt] = tgt.to_s
        $LOG.debug("Ticket granting cookie '#{@cookies[:tgt]}' granted to '#{@username}'")
                
        if @service.blank?
          $LOG.info("Successfully authenticated user '#{@username}' at '#{tgt.client_hostname}'. No service param was given, so we will not redirect.")
          @message = {:type => 'confirmation', :message => "You have successfully logged in."}
          render :login
        else
          @st = generate_service_ticket(@service, @username)        
          service_with_ticket = service_uri_with_ticket(@service, @st)
        
          $LOG.info("Redirecting authenticated user '#{@username}' at '#{@st.client_hostname}' to service '#{@service}'")
          return redirect(service_with_ticket, :status => 303) # response code 303 means "See Other" (see Appendix B in CAS Protocol spec)
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
      # The behaviour here is somewhat non-standard. Rather than showing just a blank
      # "logout" page, we take the user back to the login page with a "you have been logged out"
      # message, allowing for an opportunity to immediately log back in. This makes
      # switching users a lot smoother.
      @service = @input['url'] || @input['service']
      # TODO: display service name in view as per 2.3.2
      
      tgt = CASServer::Models::TicketGrantingTicket.find_by_ticket(@cookies[:tgt])
      
      @cookies.delete :tgt
      
      if tgt
        pgts = CASServer::Models::ProxyGrantingTicket.find(:all, 
          :conditions => ["username = ?", tgt.username],
          :include => :service_ticket)
        pgts.each do |pgt|
          $LOG.debug("Deleting Proxy-Granting Ticket '#{pgt}' for user '#{pgt.service_ticket.username}'")
          pgt.destroy
        end
        
        $LOG.debug("Deleting Ticket-Granting Ticket '#{tgt}' for user '#{tgt.username}'")
        tgt.destroy
        
        $LOG.info("User '#{tgt.username}' logged out.")
      else
        $LOG.warn("User tried to log out without a valid ticket-granting ticket.")
      end
      
      @message = {:type => 'confirmation', :message => "You have successfully logged out."}
      
      @lt = generate_login_ticket
      
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
        
      end
      
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
      
      pgt, @error = validate_proxy_granting_ticket(@ticket)
      @success = pgt && !@error
      
      if @success
        @pt = generate_proxy_ticket(@target_service, pgt)
      end
      
      render :proxy
    end
  end
  
  class Themes < R '/themes/(.+)'         
    MIME_TYPES = {'.css' => 'text/css', '.js' => 'text/javascript', 
                  '.jpg' => 'image/jpeg'}
    PATH = CASServer::Conf.themes_dir || File.expand_path(File.dirname(__FILE__))+'/../themes'

    def get(path)
      @headers['Content-Type'] = MIME_TYPES[path[/\.\w+$/, 0]] || "text/plain"
      unless path.include? ".." # prevent directory traversal attacks
        @headers['X-Sendfile'] = "#{PATH}/#{path}"
      else
        @status = "403"
        "403 - Invalid path"
      end
    end
  end
end