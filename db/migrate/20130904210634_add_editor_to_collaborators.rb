class AddEditorToCollaborators < ActiveRecord::Migration
  def change
    add_column :collaborators, :editor, :boolean
  end
end
