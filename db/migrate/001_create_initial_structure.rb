class CreateInitialStructure < ActiveRecord::Migration
  def self.up
    # Oracle table names cannot exceed 30 chars...
    # See http://code.google.com/p/rubycas-server/issues/detail?id=15
    create_table 'casserver_lt', :force => true do |t|
      t.string    'ticket',          :null => false
      t.timestamp 'created_on',      :null => false
      t.datetime  'consumed',        :null => true
      t.string    'client_hostname', :null => false
    end

    create_table 'casserver_st', :force => true do |t|
      t.string    'ticket',            :null => false
      t.text      'service',           :null => false
      t.timestamp 'created_on',        :null => false
      t.datetime  'consumed',          :null => true
      t.string    'client_hostname',   :null => false
      t.string    'username',          :null => false
      t.string    'type',              :null => false
      t.integer   'granted_by_pgt_id', :null => true
      t.integer   'granted_by_tgt_id', :null => true
    end

    create_table 'casserver_tgt', :force => true do |t|
      t.string    'ticket',           :null => false
      t.timestamp 'created_on',       :null => false
      t.string    'client_hostname',  :null => false
      t.string    'username',         :null => false
      t.text      'extra_attributes', :null => true
    end

    create_table 'casserver_pgt', :force => true do |t|
      t.string    'ticket',            :null => false
      t.timestamp 'created_on',        :null => false
      t.string    'client_hostname',   :null => false
      t.string    'iou',               :null => false
      t.integer   'service_ticket_id', :null => false
    end
  end # self.up

  def self.down
    drop_table 'casserver_pgt'
    drop_table 'casserver_tgt'
    drop_table 'casserver_st'
    drop_table 'casserver_lt'
  end # self.down
end
