require 'camping/db'

module CASServer::Models
  
  class LoginTicket < Base
    def to_s
      ticket
    end
  end
  
  class ServiceTicket < Base
    def to_s
      ticket
    end
  end
  
  class Error
    attr_reader :code, :message
    
    def initialize(code, message)
      @code = code
      @message = message
    end
    
    def to_s
      message
    end
  end

  class CreateCASServer < V 0.1
    def self.up
      $LOG.info "Migrating database"
      
      create_table :casserver_login_tickets, :force => true do |t|
        t.column :ticket,  :string,   :null => false
        t.column :created_on, :timestamp, :null => false
        t.column :client_hostname, :string, :null => false
      end
    
      create_table :casserver_service_tickets, :force => true do |t|
        t.column :ticket,     :string,    :null => false
        t.column :service,    :string,    :null => false
        t.column :created_on, :timestamp, :null => false
        t.column :client_hostname, :string, :null => false
        t.column :username,   :string,  :null => false
      end
    end
    
    def self.down
      drop_table :casserver_service_tickets
      drop_table :casserver_login_tickets
    end
  end
end