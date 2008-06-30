# The #.#.# comments (e.g. "2.1.3") refer to section numbers in the CAS protocol spec
# under http://www.ja-sig.org/products/cas/overview/protocol/index.html

module CASServer::Controllers

  # 2.1
  class Login < R '/', '/login'
    include CASServer::CAS
    
    # 2.1.1
    def get
      CASServer::Utils::log_controller_action(self.class, @input)
      
      # make sure there's no caching
      headers['Pragma'] = 'no-cache'
      headers['Cache-Control'] = 'no-store'
      headers['Expires'] = (Time.now - 1.year).rfc2822
      
      # optional params
      @service = clean_service_url(@input['service'])
      @renew = @input['renew']
      @gateway = @input['gateway'] == 'true' || @input['gateway'] == '1'
      
      if tgc = @cookies[:tgt]
        tgt, tgt_error = validate_ticket_granting_ticket(tgc)
      end
      
      if tgt and !tgt_error
        @message = {:type => 'notice', 
          :message => %{You are currently logged in as "#{tgt.username}". If this is not you, please log in below.}}
      end

      if @input['redirection_loop_intercepted']
        @message = {:type => 'mistake', 
          :message => %{The client and server are unable to negotiate authentication. Please try logging in again later.}}
      end
      
      begin
        if @service 
          if !@renew && tgt && !tgt_error
            st = generate_service_ticket(@service, tgt.username, tgt)
            service_with_ticket = service_uri_with_ticket(@service, st)
            $LOG.info("User '#{tgt.username}' authenticated based on ticket granting cookie. Redirecting to service '#{@service}'.")
            return redirect(service_with_ticket, :status => 303) # response code 303 means "See Other" (see Appendix B in CAS Protocol spec)
          elsif @gateway
            $LOG.info("Redirecting unauthenticated gateway request to service '#{@service}'.")
            return redirect(@service, :status => 303)
          end
        elsif @gateway
            $LOG.error("This is a gateway request but no service parameter was given!")
            @message = {:type => 'mistake', 
              :message => "The server cannot fulfill this gateway request because no service parameter was given."}
        end
      rescue URI::InvalidURIError
        $LOG.error("The service '#{@service}' is not a valid URI!")
        @message = {:type => 'mistake', 
          :message => "The target service your browser supplied appears to be invalid. Please contact your system administrator for help."}
      end
      
      lt = generate_login_ticket
      
      $LOG.debug("Rendering login form with lt: #{lt}, service: #{@service}, renew: #{@renew}, gateway: #{@gateway}")
      
      @lt = lt.ticket
      
      #$LOG.debug(env)
      
      # If the 'onlyLoginForm' parameter is specified, we will only return the 
      # login form part of the page. This is useful for when you want to
      # embed the login form in some external page (as an IFRAME, or otherwise).
      # The optional 'submitToURI' parameter can be given to explicitly set the
      # action for the form, otherwise the server will try to guess this for you.
      if @input.has_key? 'onlyLoginForm'
        if env['HTTP_HOST']
          guessed_login_uri = "http#{env['HTTPS'] && env['HTTPS'] == 'on' ? 's' : ''}://#{env['REQUEST_URI']}#{self / '/login'}"
        else
          guessed_login_uri = nil
        end

        @form_action = @input['submitToURI'] || guessed_login_uri
        
        if @form_action
          render :login_form
        else
          @status = 500
          "Could not guess the CAS login URI. Please supply a submitURI parameter with your request."
        end
      else
        render :login
      end
    end
    
    # 2.2
    def post
      CASServer::Utils::log_controller_action(self.class, @input)
      
      # 2.2.1 (optional)
      @service = clean_service_url(@input['service'])
      
      # FIXME: This is a potential security/phishing hole! Maybe @warn should 
      #        be the id of a registered error string, rather than blindly
      #        printing whatever message the client wants printed... although
      #        I can't figure out if this is even used at all anymore. 
      @warn = @input['warn']
      
      # 2.2.2 (required)
      @username = @input['username']
      @password = @input['password']
      @lt = @input['lt']
      
      # Remove leading and trailing widespace from username.
      @username.strip! if @username
      
      if @username && $CONF[:downcase_username]
        $LOG.debug("Converting username #{@username.inspect} to lowercase because 'downcase_username' option is enabled.")
        @username.downcase!
      end
      
      if error = validate_login_ticket(@lt)
        @message = {:type => 'mistake', :message => error}
        # generate another login ticket to allow for re-submitting the form
        @lt = generate_login_ticket.ticket
        @status = 401
        return render(:login)
      end
      
      # generate another login ticket to allow for re-submitting the form after a post
      @lt = generate_login_ticket.ticket
      
      if $CONF[:authenticator].instance_of? Array
        $AUTH.each_index {|auth_index| $AUTH[auth_index].configure(CASServer::Conf.authenticator[auth_index])}
      else
        $AUTH[0].configure(CASServer::Conf.authenticator)
      end

      $LOG.debug("Logging in with username: #{@username}, lt: #{@lt}, service: #{@service}, auth: #{$AUTH}")
      
      credentials_are_valid = false
      extra_attributes = {}
      begin
        $AUTH.each do |auth|
          credentials_are_valid = auth.validate(
            :username => @username, 
            :password => @password, 
            :service => @service,
            :request => env
          )
          if credentials_are_valid
            extra_attributes.merge!(auth.extra_attributes) unless auth.extra_attributes.blank?
            break 
          end
        end
      rescue CASServer::AuthenticatorError => e
        $LOG.error(e)
        @message = {:type => 'mistake', :message => e.to_s}
        return render(:login)
      end
      
      if credentials_are_valid
        $LOG.info("Credentials for username '#{@username}' successfully validated")
        $LOG.debug("Authenticator provided additional user attributes: #{extra_attributes.inspect}") unless extra_attributes.blank?
        
        # 3.6 (ticket-granting cookie)
        tgt = generate_ticket_granting_ticket(@username, extra_attributes)
        
        if CASServer::Conf.expire_sessions
          expires = CASServer::Conf.ticket_granting_ticket_expiry.to_i.from_now
          expiry_info = " It will expire on #{expires}."
        else
          expiry_info = " It will not expire."
        end
        
        if CASServer::Conf.expire_sessions
          @cookies[:tgt] = {
            :value => tgt.to_s, 
            :expires => Time.now + CASServer::Conf.ticket_granting_ticket_expiry
          }
        else
          @cookies[:tgt] = tgt.to_s
        end
        
        $LOG.debug("Ticket granting cookie '#{@cookies[:tgt].inspect}' granted to '#{@username.inspect}'. #{expiry_info}")
                
        if @service.blank?
          $LOG.info("Successfully authenticated user '#{@username}' at '#{tgt.client_hostname}'. No service param was given, so we will not redirect.")
          @message = {:type => 'confirmation', :message => "You have successfully logged in."}
        else
          @st = generate_service_ticket(@service, @username, tgt)
          begin
            service_with_ticket = service_uri_with_ticket(@service, @st)
            
            $LOG.info("Redirecting authenticated user '#{@username}' at '#{@st.client_hostname}' to service '#{@service}'")
            return redirect(service_with_ticket, :status => 303) # response code 303 means "See Other" (see Appendix B in CAS Protocol spec)
          rescue URI::InvalidURIError
            $LOG.error("The service '#{@service}' is not a valid URI!")
            @message = {:type => 'mistake', :message => "The target service your browser supplied appears to be invalid. Please contact your system administrator for help."}
          end
        end
      else
        $LOG.warn("Invalid credentials given for user '#{@username}'")
        @message = {:type => 'mistake', :message => "Incorrect username or password."}
        @status = 401
      end
      
      render :login
    end
  end
  
  # 2.3
  class Logout < R '/logout'
    include CASServer::CAS
    
    # 2.3.1
    def get
      CASServer::Utils::log_controller_action(self.class, @input)
      
      # The behaviour here is somewhat non-standard. Rather than showing just a blank
      # "logout" page, we take the user back to the login page with a "you have been logged out"
      # message, allowing for an opportunity to immediately log back in. This makes it
      # easier for the user to log out and log in as someone else.
      @service = clean_service_url(@input['service'] || @input['destination'])
      @continue_url = @input['url']
      
      @gateway = @input['gateway'] == 'true' || @input['gateway'] == '1'
      
      tgt = CASServer::Models::TicketGrantingTicket.find_by_ticket(@cookies[:tgt])
      
      @cookies.delete :tgt
      
      if tgt
        CASServer::Models::TicketGrantingTicket.transaction do
          pgts = CASServer::Models::ProxyGrantingTicket.find(:all, 
            :conditions => [CASServer::Models::Base.connection.quote_table_name(CASServer::Models::ServiceTicket.table_name)+".username = ?", tgt.username],
            :include => :service_ticket) 
          pgts.each do |pgt|
            $LOG.debug("Deleting Proxy-Granting Ticket '#{pgt}' for user '#{pgt.service_ticket.username}'")
            pgt.destroy
          end
          
          if CASServer::Conf.enable_single_sign_out
            $LOG.debug("Deleting Service/Proxy Tickets for '#{tgt}' for user '#{tgt.username}'")
            tgt.service_tickets.each do |st|
              send_logout_notification_for_service_ticket(st)
              # TODO: Maybe we should do some special handling if send_logout_notification_for_service_ticket fails? 
              #       Note that the method returns false if the POST results in a non-200 HTTP response.
              $LOG.debug "Deleting #{st.class} #{st.ticket.inspect}."
              st.destroy
            end
          end
          
          $LOG.debug("Deleting Ticket-Granting Ticket '#{tgt}' for user '#{tgt.username}'")
          tgt.destroy
        end  
        
        $LOG.info("User '#{tgt.username}' logged out.")
      else
        $LOG.warn("User tried to log out without a valid ticket-granting ticket.")
      end
      
      @message = {:type => 'confirmation', :message => "You have successfully logged out."}
      
      @message[:message] << 
        " Please click on the following link to continue:" if @continue_url
      
      @lt = generate_login_ticket
      
      if @gateway && @service
        redirect(@service, :status => 303)
      elsif @continue_url
        render :logout
      else
        render :login
      end
    end
  end

  # 2.4
  class Validate < R '/validate'
    include CASServer::CAS
  
    # 2.4.1
    def get
      CASServer::Utils::log_controller_action(self.class, @input)
      
      # required
      @service = clean_service_url(@input['service'])
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
      CASServer::Utils::log_controller_action(self.class, @input)
      
      # required
      @service = clean_service_url(@input['service'])
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
        @extra_attributes = st.ticket_granting_ticket.extra_attributes || {}
      end
      
      render :service_validate
    end
  end
  
  # 2.6
  class ProxyValidate < R '/proxyValidate'
    include CASServer::CAS
  
    # 2.6.1
    def get
      CASServer::Utils::log_controller_action(self.class, @input)
      
      # required
      @service = clean_service_url(@input['service'])
      @ticket = @input['ticket']
      # optional
      @pgt_url = @input['pgtUrl']
      @renew = @input['renew']
      
      @proxies = []
      
      t, @error = validate_proxy_ticket(@service, @ticket)      
      @success = t && !@error
      
      @extra_attributes = {}
      if @success
        @username = t.username
        
        if t.kind_of? CASServer::Models::ProxyTicket
          @proxies << t.proxy_granting_ticket.service_ticket.service
        end
          
        if @pgt_url
          pgt = generate_proxy_granting_ticket(@pgt_url, t)
          @pgtiou = pgt.iou if pgt
        end
        
        @extra_attributes = t.ticket_granting_ticket.extra_attributes || {}
      end

     render :proxy_validate
    end
  end
  
  class Proxy < R '/proxy'
    include CASServer::CAS
  
    # 2.7
    def get
      CASServer::Utils::log_controller_action(self.class, @input)
      
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
  
  # Controller for obtaining login tickets.
  # This is useful when you want to build a custom login form located on a 
  # remote server. Your form will have to include a valid login ticket
  # value, and this can be fetched from the CAS server using this controller'
  # POST method.
  class LoginTicketDispenser < R '/loginTicket'
    include CASServer::CAS
    
    def get
      CASServer::Utils::log_controller_action(self.class, @input)
      $LOG.error("Tried to use login ticket dispenser with get method!")
      @status = 500
      "To generate a login ticket, you must make a POST request."
    end
    
    # Renders a page with a login ticket (and only the login ticket)
    # in the response body.
    def post
      CASServer::Utils::log_controller_action(self.class, @input)
      lt = generate_login_ticket
      
      $LOG.debug("Dispensing login ticket #{lt} to host #{(env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']).inspect}")
      
      @lt = lt.ticket
      
      @lt
    end
  end
  
  class Themes < R '/themes/(.+)'         
    MIME_TYPES = {'.css' => 'text/css', '.js' => 'text/javascript', 
                  '.jpg' => 'image/jpeg'}
    PATH = CASServer::Conf.themes_dir || File.expand_path(File.dirname(__FILE__))+'/../themes'

    def get(path)@headers['Content-Type'] = MIME_TYPES[path[/\.\w+$/, 0]] || "text/plain"
      unless path.include? ".." # prevent directory traversal attacks
        @headers['X-Sendfile'] = "#{PATH}/#{path}"
      else
        @status = "403"
        "403 - Invalid path"
      end
    end
  end
end
