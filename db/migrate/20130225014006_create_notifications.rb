class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.string :title
      t.text :body
      t.boolean :emailed

      t.timestamps
    end
  end
end
