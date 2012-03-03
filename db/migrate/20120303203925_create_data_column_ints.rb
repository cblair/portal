class CreateDataColumnInts < ActiveRecord::Migration
  def change
    create_table :data_column_ints do |t|
      t.integer :val
      t.integer :data_column_id

      t.timestamps
    end
  end
end
