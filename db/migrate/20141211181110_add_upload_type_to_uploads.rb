class AddUploadTypeToUploads < ActiveRecord::Migration
  def change
    add_column :uploads, :upload_type, :string
  end
end
