class CreateUploads < ActiveRecord::Migration
  def change
    drop_table :uploads
    create_table :uploads do |t|
      t.string :name

      t.timestamps
    end
  end
end
