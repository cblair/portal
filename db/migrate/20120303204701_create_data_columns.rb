class CreateDataColumns < ActiveRecord::Migration
  def change
    create_table :data_columns do |t|
      t.string :name
      t.string :dtype
      t.integer :order
      t.integer :datum_id

      t.timestamps
    end
  end
end
