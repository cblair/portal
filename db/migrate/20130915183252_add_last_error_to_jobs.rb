class AddLastErrorToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :Job, :string
    add_column :jobs, :last_error, :text
  end
end
