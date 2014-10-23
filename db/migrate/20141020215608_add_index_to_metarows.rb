class AddIndexToMetarows < ActiveRecord::Migration
  def change
    add_column :metarows, :index, :integer
  end
end
