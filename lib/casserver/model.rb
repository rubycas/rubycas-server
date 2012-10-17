require 'casserver/model/consumable'
require 'casserver/model/ticket'
require 'active_record'

module CASServer::Model

  class LoginTicket < ActiveRecord::Base
    include Consumable
    include Ticket

    if ActiveRecord::VERSION::STRING >= '3.2'
      self.table_name = 'casserver_lt'
    else
      set_table_name 'casserver_lt'
    end
  end

  class SPTicket < ActiveRecord::Base
    include Consumable
    include Ticket

    if ActiveRecord::VERSION::STRING >= '3.2'
      self.table_name = 'casserver_st'
    else
      set_table_name 'casserver_st'
    end

    def matches_service?(service)
      CASServer::CAS.clean_service_url(self.service) ==
        CASServer::CAS.clean_service_url(service)
    end
  end

  class ServiceTicket < SPTicket
    belongs_to :granted_by_tgt,
      :class_name => 'CASServer::Model::TicketGrantingTicket',
      :foreign_key => :granted_by_tgt_id
    has_one :proxy_granting_ticket,
      :foreign_key => :created_by_st_id
  end

  class ProxyTicket < SPTicket
    belongs_to :granted_by_pgt,
      :class_name => 'CASServer::Model::ProxyGrantingTicket',
      :foreign_key => :granted_by_pgt_id
  end

  class TicketGrantingTicket < ActiveRecord::Base
    include Ticket

    if ActiveRecord::VERSION::STRING >= '3.2'
      self.table_name = 'casserver_tgt'
    else
      set_table_name 'casserver_tgt'
    end

    serialize :extra_attributes

    has_many :granted_service_tickets,
      :class_name => 'CASServer::Model::ServiceTicket',
      :foreign_key => :granted_by_tgt_id
  end

  class ProxyGrantingTicket < ActiveRecord::Base
    include Ticket

    if ActiveRecord::VERSION::STRING >= '3.2'
      self.table_name = 'casserver_pgt'
    else
      set_table_name 'casserver_pgt'
    end
    belongs_to :service_ticket
    has_many :granted_proxy_tickets,
      :class_name => 'CASServer::Model::ProxyTicket',
      :foreign_key => :granted_by_pgt_id
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

#  class CreateCASServer < V 0.1
#    def self.up
#      if ActiveRecord::Base.connection.table_alias_length > 30
#        $LOG.info("Creating database with long table names...")
#
#        create_table :casserver_login_tickets, :force => true do |t|
#          t.column :ticket,     :string,   :null => false
#          t.column :created_on, :timestamp, :null => false
#          t.column :consumed,   :datetime, :null => true
#          t.column :client_hostname, :string, :null => false
#        end
#
#        create_table :casserver_service_tickets, :force => true do |t|
#          t.column :ticket,     :string,    :null => false
#          t.column :service,    :string,    :null => false
#          t.column :created_on, :timestamp, :null => false
#          t.column :consumed,   :datetime, :null => true
#          t.column :client_hostname, :string, :null => false
#          t.column :username,   :string,  :null => false
#          t.column :type,       :string,   :null => false
#          t.column :proxy_granting_ticket_id, :integer, :null => true
#        end
#
#        create_table :casserver_ticket_granting_tickets, :force => true do |t|
#          t.column :ticket,     :string,    :null => false
#          t.column :created_on, :timestamp, :null => false
#          t.column :client_hostname, :string, :null => false
#          t.column :username,   :string,    :null => false
#        end
#
#        create_table :casserver_proxy_granting_tickets, :force => true do |t|
#          t.column :ticket,     :string,    :null => false
#          t.column :created_on, :timestamp, :null => false
#          t.column :client_hostname, :string, :null => false
#          t.column :iou,        :string,    :null => false
#          t.column :service_ticket_id, :integer, :null => false
#        end
#      end
#    end
#
#    def self.down
#      if ActiveRecord::Base.connection.table_alias_length > 30
#        drop_table :casserver_proxy_granting_tickets
#        drop_table :casserver_ticket_granting_tickets
#        drop_table :casserver_service_tickets
#        drop_table :casserver_login_tickets
#      end
#    end
#  end
#
#  # Oracle table names cannot exceed 30 chars...
#  # See http://code.google.com/p/rubycas-server/issues/detail?id=15
#  class ShortenTableNames < V 0.5
#    def self.up
#      if ActiveRecord::Base.connection.table_alias_length > 30
#        $LOG.info("Shortening table names")
#        rename_table :casserver_login_tickets, :casserver_lt
#        rename_table :casserver_service_tickets, :casserver_st
#        rename_table :casserver_ticket_granting_tickets, :casserver_tgt
#        rename_table :casserver_proxy_granting_tickets, :casserver_pgt
#      else
#        create_table :casserver_lt, :force => true do |t|
#          t.column :ticket,     :string,   :null => false
#          t.column :created_on, :timestamp, :null => false
#          t.column :consumed,   :datetime, :null => true
#          t.column :client_hostname, :string, :null => false
#        end
#
#        create_table :casserver_st, :force => true do |t|
#          t.column :ticket,     :string,    :null => false
#          t.column :service,    :string,    :null => false
#          t.column :created_on, :timestamp, :null => false
#          t.column :consumed,   :datetime, :null => true
#          t.column :client_hostname, :string, :null => false
#          t.column :username,   :string,  :null => false
#          t.column :type,       :string,   :null => false
#          t.column :proxy_granting_ticket_id, :integer, :null => true
#        end
#
#        create_table :casserver_tgt, :force => true do |t|
#          t.column :ticket,     :string,    :null => false
#          t.column :created_on, :timestamp, :null => false
#          t.column :client_hostname, :string, :null => false
#          t.column :username,   :string,    :null => false
#        end
#
#        create_table :casserver_pgt, :force => true do |t|
#          t.column :ticket,     :string,    :null => false
#          t.column :created_on, :timestamp, :null => false
#          t.column :client_hostname, :string, :null => false
#          t.column :iou,        :string,    :null => false
#          t.column :service_ticket_id, :integer, :null => false
#        end
#      end
#    end
#
#    def self.down
#      if ActiveRecord::Base.connection.table_alias_length > 30
#        rename_table :casserver_lt, :cassserver_login_tickets
#        rename_table :casserver_st, :casserver_service_tickets
#        rename_table :casserver_tgt, :casserver_ticket_granting_tickets
#        rename_table :casserver_pgt, :casserver_proxy_granting_tickets
#      else
#        drop_table :casserver_pgt
#        drop_table :casserver_tgt
#        drop_table :casserver_st
#        drop_table :casserver_lt
#      end
#    end
#  end
#
#  class AddTgtToSt < V 0.7
#    def self.up
#      add_column :casserver_st, :tgt_id, :integer, :null => true
#    end
#
#    def self.down
#      remove_column :casserver_st, :tgt_id, :integer
#    end
#  end
#
#  class ChangeServiceToText < V 0.71
#    def self.up
#      # using change_column to change the column type from :string to :text
#      # doesn't seem to work, at least under MySQL, so we drop and re-create
#      # the column instead
#      remove_column :casserver_st, :service
#      say "WARNING: All existing service tickets are being deleted."
#      add_column :casserver_st, :service, :text
#    end
#
#    def self.down
#      change_column :casserver_st, :service, :string
#    end
#  end
#
#  class AddExtraAttributes < V 0.72
#    def self.up
#      add_column :casserver_tgt, :extra_attributes, :text
#    end
#
#    def self.down
#      remove_column :casserver_tgt, :extra_attributes
#    end
#  end
#
#  class RenamePgtForeignKeys < V 0.80
#    def self.up
#      rename_column :casserver_st,  :proxy_granting_ticket_id,  :granted_by_pgt_id
#      rename_column :casserver_st,  :tgt_id,                    :granted_by_tgt_id
#    end
#
#    def self.down
#      rename_column :casserver_st,  :granted_by_pgt_id,         :proxy_granting_ticket_id
#      rename_column :casserver_st,  :granted_by_tgt_id,         :tgt_id
#    end
#  end
end
