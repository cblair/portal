class AddJobIdToDelayedJobs < ActiveRecord::Migration
  def change
    add_column :delayed_jobs, :job_id, :integer
  end
end
