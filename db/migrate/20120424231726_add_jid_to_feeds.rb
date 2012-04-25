class AddJidToFeeds < ActiveRecord::Migration
  def change
    add_column :feeds, :jid, :integer
  end
end
