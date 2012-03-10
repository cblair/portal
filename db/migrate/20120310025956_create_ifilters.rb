class CreateIfilters < ActiveRecord::Migration
  def change
    create_table :ifilters do |t|
      t.string :name
      t.string :regex

      t.timestamps
    end
  end
end
