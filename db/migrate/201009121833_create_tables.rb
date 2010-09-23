class CreateTables < ActiveRecord::Migration
  def self.up
    create_table :casserver_lt, :force => true do |t|
      t.column :ticket,     :string,   :null => false
      t.column :created_on, :timestamp, :null => false
      t.column :consumed,   :datetime, :null => true
      t.column :client_hostname, :string, :null => false
    end

    create_table :casserver_st, :force => true do |t|
      t.column :ticket,     :string,    :null => false
      t.column :service,    :text,    :null => false
      t.column :created_on, :timestamp, :null => false
      t.column :consumed,   :datetime, :null => true
      t.column :client_hostname, :string, :null => false
      t.column :username,   :string,  :null => false
      t.column :type,       :string,   :null => false
      t.column :granted_by_pgt_id, :integer, :null => true
      t.column :granted_by_tgt_id, :integer, :null => true
    end

    create_table :casserver_tgt, :force => true do |t|
      t.column :ticket,     :string,    :null => false
      t.column :created_on, :timestamp, :null => false
      t.column :client_hostname, :string, :null => false
      t.column :username,   :string,    :null => false
      t.column :extra_attributes, :text
    end

    create_table :casserver_pgt, :force => true do |t|
      t.column :ticket,     :string,    :null => false
      t.column :created_on, :timestamp, :null => false
      t.column :client_hostname, :string, :null => false
      t.column :iou,        :string,    :null => false
      t.column :service_ticket_id, :integer, :null => false
    end
  end
  
  def self.down
    
  end
end