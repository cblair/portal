class CreateCharts < ActiveRecord::Migration
  def change
    create_table :charts do |t|
      t.string :title
      t.string :x_column
      t.string :y_column
      t.string :xlab
      t.string :ylab
      t.string :chart_type
      t.text :options
      t.integer :source_doc
      t.timestamps
    end
  end
end
