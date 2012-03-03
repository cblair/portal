class CreateData < ActiveRecord::Migration
  def change
    create_table :data do |t|
      t.string :param1
      t.string :param2
      t.string :param3
      t.integer :metadatum_id

      t.timestamps
    end
  end
end
