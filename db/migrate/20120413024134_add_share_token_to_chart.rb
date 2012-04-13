class AddShareTokenToChart < ActiveRecord::Migration
  def change
    add_column :charts, :share_token, :string
  end
end
