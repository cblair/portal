class AddArIdToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :ar_id, :integer
  end
end
