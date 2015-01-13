class CreateDocumentsUploadsTable < ActiveRecord::Migration
  def up
    create_table :documents_uploads, :id => false do |t|
        t.references :document
        t.references :upload
    end
  end

  def down
    drop_table :documents_uploads
  end
end
