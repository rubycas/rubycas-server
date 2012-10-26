class AddIndexesForPerformance < ActiveRecord::Migration
  def self.up
    add_index :casserver_lt,  :ticket
    add_index :casserver_st,  :ticket
    add_index :casserver_tgt, :ticket
    add_index :casserver_pgt, :ticket
  end

  def self.down
    remove_index  :casserver_pgt, :ticket
    remove_index  :casserver_st,  :ticket
    remove_index  :casserver_lt,  :ticket
    remove_index  :casserver_tgt, :ticket
  end
end