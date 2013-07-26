class CollectionsBelongToManyProjects < ActiveRecord::Migration
  def change
    create_table :collections_projects, :id => false do |t|
      t.integer :collection_id
      t.integer :project_id
    end
  end
end
