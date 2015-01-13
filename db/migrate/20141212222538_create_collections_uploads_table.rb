class CreateCollectionsUploadsTable < ActiveRecord::Migration
  def up
    create_table :collections_uploads, :id => false do |t|
        t.references :collection
        t.references :upload
    end
  end

  def down
    drop_table :collections_uploads
  end
end
