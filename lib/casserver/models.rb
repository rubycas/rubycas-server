require 'camping/db'

module CASServer::Models
  
  module Consumable
    def consume!
      self.consumed = Time.now
      self.save!
    end
  end
  
  class Ticket < Base
    self.abstract_class = true
    def to_s
      ticket
    end
    
    def self.cleanup_expired(expiry_time)
      transaction do
        expired_tickets = find(:all, 
          :conditions => ["created_on < ?", Time.now - expiry_time])
          
        $LOG.debug("Destroying #{expired_tickets.size} expired #{self}"+
          "#{'s' if expired_tickets.size > 1}.") if expired_tickets.size > 0
      
        expired_tickets.each do |t|
          t.destroy
        end
      end
    end
  end
  
  class LoginTicket < Ticket
    include Consumable
  end
  
  class ServiceTicket < Ticket
    include Consumable
    
    def matches_service?(service)
      # We ignore the trailing slash in URLs, since 
      # "http://www.google.com/" and "http://www.google.com" are almost
      # certainly the same service.
      self.service.gsub(/\/$/, '') == service.gsub(/\/$/, '')
    end
  end
  
  class ProxyTicket < ServiceTicket
    belongs_to :proxy_granting_ticket
  end
  
  class TicketGrantingTicket < Ticket
  end
  
  class ProxyGrantingTicket < Ticket
    belongs_to :service_ticket
    has_many :proxy_tickets, :dependent => :destroy
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
      $LOG.info("Migrating database")
      
      create_table :casserver_login_tickets, :force => true do |t|
        t.column :ticket,     :string,   :null => false
        t.column :created_on, :timestamp, :null => false
        t.column :consumed,   :datetime, :null => true
        t.column :client_hostname, :string, :null => false
      end
    
      create_table :casserver_service_tickets, :force => true do |t|
        t.column :ticket,     :string,    :null => false
        t.column :service,    :string,    :null => false
        t.column :created_on, :timestamp, :null => false
        t.column :consumed,   :datetime, :null => true
        t.column :client_hostname, :string, :null => false
        t.column :username,   :string,  :null => false
        t.column :type,       :string,   :null => false
        t.column :proxy_granting_ticket_id, :integer, :null => true
      end
      
      create_table :casserver_ticket_granting_tickets, :force => true do |t|
        t.column :ticket,     :string,    :null => false
        t.column :created_on, :timestamp, :null => false
        t.column :client_hostname, :string, :null => false
        t.column :username,   :string,    :null => false
      end
      
      create_table :casserver_proxy_granting_tickets, :force => true do |t|
        t.column :ticket,     :string,    :null => false
        t.column :created_on, :timestamp, :null => false
        t.column :client_hostname, :string, :null => false
        t.column :iou,        :string,    :null => false
        t.column :service_ticket_id, :integer, :null => false
      end
    end
    
    def self.down
      drop_table :casserver_service_tickets
      drop_table :casserver_login_tickets
    end
  end
end