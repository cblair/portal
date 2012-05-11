class CreateFeeds < ActiveRecord::Migration
  def change
    if ActiveRecord::Base.connection.table_exists? 'feeds'
    then drop_table :feeds
    end
    create_table :feeds do |t|
      t.string :name
      t.string :feed_url
      t.integer :interval_val
      t.string :interval_unit
      t.integer :document_id

      t.timestamps
    end
  end
end
