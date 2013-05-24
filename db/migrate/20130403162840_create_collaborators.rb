class CreateCollaborators < ActiveRecord::Migration
  def change
    create_table :collaborators do |t|
      t.integer :project_id
      t.string :project_name
      t.integer :user_id
      t.string :user_email

      t.timestamps
    end
  end
end
