class Job < ActiveRecord::Base
  require 'spawn'

  attr_accessible :description, :finished, :user_id

  belongs_to :user

  def submit_job(options)
  	if (self.ar_name == nil or self.ar_id == nil)
  		return false
  	end

  	ar_module = eval(self.ar_name).find(self.ar_id)
 
 	self.started = true

  	#spawn_block do
  	Thread.new do
  		#ensure we have a new connection with the db pool; each thread needs a new
  		# connection
  		begin
	  		ActiveRecord::Base.connection_pool.with_connection do
	  			#wait for a few seconds before we start
		  		sleep 5
		  		ar_module.submit_job(self, options)
		  	end
		rescue ActiveRecord::ConnectionTimeoutError
			puts "WARN: Job #{self.id} waiting to start job on DB connection, sleeping 10 seconds..."
			sleep 10
			retry
		end
  	end

  	self.finished = true

  	return true
  end
end
