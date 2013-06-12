class AddWaitingToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :waiting, :boolean
  end
end
