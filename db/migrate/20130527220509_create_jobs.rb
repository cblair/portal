class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.text :description
      t.integer :user_id
      t.boolean :finished

      t.timestamps
    end
  end
end
