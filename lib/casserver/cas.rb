require 'uri'
require 'net/https'

# Encapsulates CAS functionality. This module is meant to be included in
# the CASServer::Controllers module.
module CASServer::CAS

  include CASServer::Models

  def generate_login_ticket
    # 3.5 (login ticket)
    lt = LoginTicket.new
    lt.ticket = "LT-" + CASServer::Utils.random_string
    lt.client_hostname = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']
    lt.save!
    $LOG.debug("Generated login ticket '#{lt.ticket}' for client" +
      " at '#{lt.client_hostname}'")
    lt
  end
  
  # Creates a TicketGrantingTicket for the given username. This is done when the user logs in
  # for the first time to establish their SSO session (after their credentials have been validated).
  #
  # The optional 'extra_attributes' parameter takes a hash of additional attributes
  # that will be sent along with the username in the CAS response to subsequent 
  # validation requests from clients.
  def generate_ticket_granting_ticket(username, extra_attributes = {})
    # 3.6 (ticket granting cookie/ticket)
    tgt = TicketGrantingTicket.new
    tgt.ticket = "TGC-" + CASServer::Utils.random_string
    tgt.username = username
    tgt.extra_attributes = extra_attributes
    tgt.client_hostname = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']
    tgt.save!
    $LOG.debug("Generated ticket granting ticket '#{tgt.ticket}' for user" +
      " '#{tgt.username}' at '#{tgt.client_hostname}'" + 
      (extra_attributes.blank? ? "" : " with extra attributes #{extra_attributes.inspect}"))
    tgt
  end
  
  def generate_service_ticket(service, username, tgt)
    # 3.1 (service ticket)
    st = ServiceTicket.new
    st.ticket = "ST-" + CASServer::Utils.random_string
    st.service = service
    st.username = username
    st.ticket_granting_ticket = tgt
    st.client_hostname = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']
    st.save!
    $LOG.debug("Generated service ticket '#{st.ticket}' for service '#{st.service}'" +
      " for user '#{st.username}' at '#{st.client_hostname}'")
    st
  end
  
  def generate_proxy_ticket(target_service, pgt)
    # 3.2 (proxy ticket)
    pt = ProxyTicket.new
    pt.ticket = "PT-" + CASServer::Utils.random_string
    pt.service = target_service
    pt.username = pgt.service_ticket.username
    pt.proxy_granting_ticket_id = pgt.id
    pt.ticket_granting_ticket = pgt.service_ticket.ticket_granting_ticket
    pt.client_hostname = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']
    pt.save!
    $LOG.debug("Generated proxy ticket '#{pt.ticket}' for target service '#{pt.service}'" +
      " for user '#{pt.username}' at '#{pt.client_hostname}' using proxy-granting" +
      " ticket '#{pgt.ticket}'")
    pt
  end
  
  def generate_proxy_granting_ticket(pgt_url, st)
    uri = URI.parse(pgt_url)
    https = Net::HTTP.new(uri.host,uri.port)
    https.use_ssl = true
    
    # Here's what's going on here:
    # 
    #   1. We generate a ProxyGrantingTicket (but don't store it in the database just yet)
    #   2. Deposit the PGT and it's associated IOU at the proxy callback URL.
    #   3. If the proxy callback URL responds with HTTP code 200, store the PGT and return it;
    #      otherwise don't save it and return nothing.
    #      
    https.start do |conn|
      path = uri.path.empty? ? '/' : uri.path
      
      pgt = ProxyGrantingTicket.new
      pgt.ticket = "PGT-" + CASServer::Utils.random_string(60)
      pgt.iou = "PGTIOU-" + CASServer::Utils.random_string(57)
      pgt.service_ticket_id = st.id
      pgt.client_hostname = env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_HOST'] || env['REMOTE_ADDR']
      
      # FIXME: The CAS protocol spec says to use 'pgt' as the parameter, but in practice
      #         the JA-SIG and Yale server implementations use pgtId. We'll go with the
      #         in-practice standard.
      path += (uri.query.nil? || uri.query.empty? ? '?' : '&') + "pgtId=#{pgt.ticket}&pgtIou=#{pgt.iou}"
      
      response = conn.request_get(path)
      # TODO: follow redirects... 2.5.4 says that redirects MAY be followed
      
      if response.code.to_i == 200
        # 3.4 (proxy-granting ticket IOU)
        pgt.save!
        $LOG.debug "PGT generated for pgt_url '#{pgt_url}': #{pgt.inspect}"
        pgt
      else
        $LOG.warn "PGT callback server responded with a bad result code '#{response.code}'. PGT will not be stored."
      end
    end
  end
  
  def validate_login_ticket(ticket)
    $LOG.debug("Validating login ticket '#{ticket}'")
  
    success = false
    if ticket.nil?
      error = "Your login request did not include a login ticket. There may be a problem with the authentication system."
      $LOG.warn("Missing login ticket.")
    elsif lt = LoginTicket.find_by_ticket(ticket)
      if lt.consumed?
        error = "The login ticket you provided has already been used up. Please try logging in again."
        $LOG.warn("Login ticket '#{ticket}' previously used up")
      elsif Time.now - lt.created_on < CASServer::Conf.login_ticket_expiry
        $LOG.info("Login ticket '#{ticket}' successfully validated")
      else
        error = "Your login ticket has expired. Please try logging in again."
        $LOG.warn("Expired login ticket '#{ticket}'")
      end
    else
      error = "The login ticket you provided is invalid. Please try logging in again."
      $LOG.warn("Invalid login ticket '#{ticket}'")
    end
    
    lt.consume! if lt
    
    error
  end
  
  def validate_ticket_granting_ticket(ticket)
    $LOG.debug("Validating ticket granting ticket '#{ticket}'")
  
    if ticket.nil?
      error = "No ticket granting ticket given."
      $LOG.debug(error)
    elsif tgt = TicketGrantingTicket.find_by_ticket(ticket)
      if CASServer::Conf.expire_sessions && Time.now - tgt.created_on > CASServer::Conf.ticket_granting_ticket_expiry
        error = "Your session has expired. Please log in again."
        $LOG.info("Ticket granting ticket '#{ticket}' for user '#{tgt.username}' expired.")
      else
        $LOG.info("Ticket granting ticket '#{ticket}' for user '#{tgt.username}' successfully validated.")
      end
    else
      error = "Invalid ticket granting ticket '#{ticket}' (no matching ticket found in the database)."
      $LOG.warn(error)
    end
    
    [tgt, error]
  end

  def validate_service_ticket(service, ticket, allow_proxy_tickets = false)
    $LOG.debug("Validating service/proxy ticket '#{ticket}' for service '#{service}'")
  
    if service.nil? or ticket.nil?
      error = Error.new("INVALID_REQUEST", "Ticket or service parameter was missing in the request.")
      $LOG.warn("#{error.code} - #{error.message}")
    elsif st = ServiceTicket.find_by_ticket(ticket)
      if st.consumed?
        error = Error.new("INVALID_TICKET", "Ticket '#{ticket}' has already been used up.")
        $LOG.warn("#{error.code} - #{error.message}")
      elsif st.kind_of?(CASServer::Models::ProxyTicket) && !allow_proxy_tickets
        error = Error.new("INVALID_TICKET", "Ticket '#{ticket}' is a proxy ticket, but only service tickets are allowed here.")
        $LOG.warn("#{error.code} - #{error.message}")
      elsif Time.now - st.created_on > CASServer::Conf.service_ticket_expiry
        error = Error.new("INVALID_TICKET", "Ticket '#{ticket}' has expired.")
        $LOG.warn("Ticket '#{ticket}' has expired.")
      elsif !st.matches_service? service
        error = Error.new("INVALID_SERVICE", "The ticket '#{ticket}' belonging to user '#{st.username}' is valid,"+
          " but the requested service '#{service}' does not match the service '#{st.service}' associated with this ticket.")
        $LOG.warn("#{error.code} - #{error.message}")
      else
        $LOG.info("Ticket '#{ticket}' for service '#{service}' for user '#{st.username}' successfully validated.")
      end
    else
      error = Error.new("INVALID_TICKET", "Ticket '#{ticket}' not recognized.")
      $LOG.warn("#{error.code} - #{error.message}")
    end
    
    if st
      st.consume!
    end
    
    
    [st, error]
  end
  
  def validate_proxy_ticket(service, ticket)
    pt, error = validate_service_ticket(service, ticket, true)
    
    if pt.kind_of?(CASServer::Models::ProxyTicket) && !error
      if not pt.proxy_granting_ticket
        error = Error.new("INTERNAL_ERROR", "Proxy ticket '#{pt}' belonging to user '#{pt.username}' is not associated with a proxy granting ticket.")
      elsif not pt.proxy_granting_ticket.service_ticket
        error = Error.new("INTERNAL_ERROR", "Proxy granting ticket '#{pt.proxy_granting_ticket}'"+
          " (associated with proxy ticket '#{pt}' and belonging to user '#{pt.username}' is not associated with a service ticket.")
      end
    end
    
    [pt, error]
  end
  
  def validate_proxy_granting_ticket(ticket)
    if ticket.nil?
      error = Error.new("INVALID_REQUEST", "pgt parameter was missing in the request.")
      $LOG.warn("#{error.code} - #{error.message}")
    elsif pgt = ProxyGrantingTicket.find_by_ticket(ticket)
      if pgt.service_ticket
        $LOG.info("Proxy granting ticket '#{ticket}' belonging to user '#{pgt.service_ticket.username}' successfully validated.")
      else
        error = Error.new("INTERNAL_ERROR", "Proxy granting ticket '#{ticket}' is not associated with a service ticket.")
        $LOG.error("#{error.code} - #{error.message}")
      end
    else
      error = Error.new("BAD_PGT", "Invalid proxy granting ticket '#{ticket}' (no matching ticket found in the database).")
      $LOG.warn("#{error.code} - #{error.message}")
    end
    
    [pgt, error]
  end
  
  # Takes an existing ServiceTicket object (presumably pulled from the database)
  # and sends a POST with logout information to the service that the ticket
  # was generated for.
  #
  # This makes possible the "single sign-out" functionality added in CAS 3.1.
  # See http://www.ja-sig.org/wiki/display/CASUM/Single+Sign+Out
  def send_logout_notification_for_service_ticket(st)
    uri = URI.parse(st.service)
    http = Net::HTTP.new(uri.host,uri.port)
    #http.use_ssl = true if uri.scheme = 'https'
    
    http.start do |conn|
      path = uri.path || '/'
      
      time = Time.now
      rand = CASServer::Utils.random_string
      
      data = %{<samlp:LogoutRequest ID="#{rand}" Version="2.0" IssueInstant="#{time.rfc2822}">
<saml:NameID></saml:NameID>
<samlp:SessionIndex>#{st.ticket}</samlp:SessionIndex>
</samlp:LogoutRequest>}
      
      response = conn.request_post(path, data)
      
      if response.code.to_i == 200
        $LOG.info "Logout notification successfully posted to #{st.service.inspect}."
        return true
      else
        $LOG.error "Service #{st.service.inspect} responed to logout notification with code '#{response.code}'."
        return false
      end
    end
  end
  
  def service_uri_with_ticket(service, st)
    raise ArgumentError, "Second argument must be a ServiceTicket!" unless st.kind_of? CASServer::Models::ServiceTicket
    
    # This will choke with a URI::InvalidURIError if service URI is not properly URI-escaped...
    # This exception is handled further upstream (i.e. in the controller).
    service_uri = URI.parse(service)
    
    if service.include? "?"
      if service_uri.query.empty?
        query_separator = ""
      else
        query_separator = "&"
      end
    else
      query_separator = "?"
    end
    
    service_with_ticket = service + query_separator + "ticket=" + st.ticket
    service_with_ticket
  end
  
  # Strips CAS-related parameters from a service URL and normalizes it,
  # removing trailing / and ?.
  #
  # For example, "http://google.com?ticket=12345" will be returned as
  # "http://google.com". Also, "http://google.com/" would be returned as
  # "http://google.com".
  #
  # Note that only the first occurance of each CAS-related parameter is
  # removed, so that "http://google.com?ticket=12345&ticket=abcd" would be
  # returned as "http://google.com?ticket=abcd".
  def clean_service_url(dirty_service)
    return dirty_service if dirty_service.blank?
    clean_service = dirty_service.dup
    ['service', 'ticket', 'gateway', 'renew'].each do |p|
      clean_service.sub!(Regexp.new("#{p}=[^&]*"), '')
    end
    
    clean_service.gsub!(/[\/\?]$/, '')
    
    return clean_service
  end
  module_function :clean_service_url
  
end
