class AddValidatedToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :validated, :boolean
  end
end
