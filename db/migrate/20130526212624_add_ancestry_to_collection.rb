class AddAncestryToCollection < ActiveRecord::Migration
  def self.up
    add_column :collections, :ancestry, :string
    add_index :collections, :ancestry
  end

  def self.down
    remove_index :collections, :ancestry
    remove_column :collections, :ancestry
  end
end
