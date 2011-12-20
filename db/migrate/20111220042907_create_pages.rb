class CreatePages < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.text :header
      t.text :content
      t.text :footer

      t.timestamps
    end
  end
end
