class RemoveSourceDocsFromCharts < ActiveRecord::Migration
  def up
    remove_column :charts, :source_doc
  end

  def down
    add_column :charts, :source_doc, :Document
  end
end
