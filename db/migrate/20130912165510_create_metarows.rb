class CreateMetarows < ActiveRecord::Migration
  def change
    create_table :metarows do |t|
      t.string :key
      t.string :value
      t.boolean :autofill
      t.integer :metaform_id
      t.integer :user_id

      t.timestamps
    end
  end
end
