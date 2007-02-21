# Encapsulates CAS functionality. This module is meant to be included in
# the CASServer::Controllers module.
module CASServer::CAS

  include CASServer::Models

  def generate_login_ticket
    # 3.5 (login ticket)
    lt = LoginTicket.new
    lt.ticket = "LT-" + CASServer::Utils.random_string
    lt.client_hostname = env['REMOTE_HOST'] || env['REMOTE_ADDR']
    lt.save!
    lt
  end
  
  def generate_service_ticket(service, username)
    # 3.1 (service ticket)
    st = ServiceTicket.new
    st.ticket = "ST-" + CASServer::Utils.random_string
    st.service = service
    st.username = username
    st.client_hostname = env['REMOTE_HOST'] || env['REMOTE_ADDR']
    st.save!
    st
  end
  
  def validate_login_ticket(ticket)
    success = false
    if ticket.nil?
      error = "Your login request did not include a login ticket."
      $LOG.warn(error)
    elsif lt = LoginTicket.find_by_ticket(ticket)
      if Time.now - lt.created_on < CASServer::LOGIN_TICKET_EXPIRY
        $LOG.info("Login ticket #{@ticket} successfully validated.")
      else
        error = "Your login ticket has expired."
        $LOG.warn(error)
      end
    else
      error = "The login ticket you provided is invalid."
    end
    
    lt.destroy if lt
    
    error
  end

  def validate_service_ticket(service, ticket)
    if service.nil? or ticket.nil?
      error = Error.new("INVALID_REQUEST", "Ticket or service parameter was missing in the request.")
      $LOG.warn("#{error.code} - #{error.message}")
    elsif st = ServiceTicket.find_by_ticket(ticket)
      if st.service == service
        $LOG.info("Ticket #{@ticket} for service #{@service} successfully validated.")
      else
        error = Error.new("INVALID_SERVICE", "The ticket #{@ticket} is valid,"+
          " but the service specified does not match the service associated with this ticket.")
        $LOG.warn("#{error.code} - #{error.message}")
      end
    else
      error = Error.new("INVALID_TICKET", "Ticket #{@ticket} not recognized.")
      $LOG.warn("#{error.code} - #{error.message}")
    end
    
    st.destroy if st
    
    error
  end
  
end