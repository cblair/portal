class AddStreamingToCharts < ActiveRecord::Migration
  def change
    add_column :charts, :streaming, :boolean
    add_column :charts, :numdraw, :integer
  end
end
