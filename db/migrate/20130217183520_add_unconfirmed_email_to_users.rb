class AddUnconfirmedEmailToUsers < ActiveRecord::Migration
  def change
    change_table(:users) do |t| 
      t.string   :unconfirmed_email # Only if using reconfirmable
    end
  end
end
