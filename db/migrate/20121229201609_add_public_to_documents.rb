class AddPublicToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :public, :boolean
  end
end
