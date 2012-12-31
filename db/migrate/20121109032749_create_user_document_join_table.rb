class CreateUserDocumentJoinTable < ActiveRecord::Migration
  def change
    create_table :users_documents, :id => false do |t|
      t.integer :user_id
      t.integer :document_id
    end
  end
end
