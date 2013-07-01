class AddProjectIdToDocuments < ActiveRecord::Migration
  def change
    add_column :documents, :project_id, :integer
  end
end
