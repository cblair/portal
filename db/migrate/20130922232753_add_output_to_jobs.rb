class AddOutputToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :output, :text
  end
end
