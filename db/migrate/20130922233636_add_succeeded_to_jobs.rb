class AddSucceededToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :succeeded, :boolean
  end
end
