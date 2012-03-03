class CreateMetaData < ActiveRecord::Migration
  def change
    create_table :metadata do |t|
      t.string :name

      t.timestamps
    end
  end
end
