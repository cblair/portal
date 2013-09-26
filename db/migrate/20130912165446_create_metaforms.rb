class CreateMetaforms < ActiveRecord::Migration
  def change
    create_table :metaforms do |t|
      t.string :name
      t.text :mddesc
      t.integer :user_id

      t.timestamps
    end
  end
end
