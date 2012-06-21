class AddCollectionIdToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :collection_id, :integer
  end
end
