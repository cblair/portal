class AddArNameToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :ar_name, :string
  end
end
