class Job < ActiveRecord::Base
  require 'spawn'

  attr_accessible :description, :finished, :user_id

  belongs_to :user

  def submit_job(ar_module, options)
  	spawn_block do
  		ar_module.submit_job(self, options)
  	end
  end
end
