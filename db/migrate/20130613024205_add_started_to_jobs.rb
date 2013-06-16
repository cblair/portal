class AddStartedToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :started, :boolean
  end
end
