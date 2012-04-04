class AddDatabaseRelationships < ActiveRecord::Migration
  def change
   change_table :charts do |t|
       t.references :document
   end

   change_table :collections do |t|
       t.references :users
   end
  end
end
