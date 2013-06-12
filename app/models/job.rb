class Job < ActiveRecord::Base
  require 'spawn'

  attr_accessible :description, :finished, :user_id

  belongs_to :user

  def submit_job(options)
  	if (self.ar_name == nil or self.ar_id == nil)
  		return false
  	end

  	ar_module = eval(self.ar_name).find(self.ar_id)
  	#spawn_block do
  		ar_module.submit_job(self, options)
  	#end

  	return true
  end
end
