class AddValidatedToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :validated, :boolean
  end
end
