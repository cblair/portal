class Job < ActiveRecord::Base
  require 'spawn'

  attr_accessible :description, :finished, :user_id

  belongs_to :user
  has_one :delayed_job

=begin
  def perform
    #? ar_module.submit_job(self, options)

    self.finished = true
    self.save
  end
=end

  def submit_job(current_user, ar_module, options)
    self.user = current_user
    self.waiting = true

    job_type = Portal::Application.config.job_type
    #job_type = "threads" #SAS need to make validations work?

    if job_type == "threads"
      self.submit_job_threads(ar_module, options)
    elsif job_type == "delayed_job"
      self.submit_job_delayed_job(ar_module, options)
    end
  end


  def submit_job_delayed_job(ar_module, options)
    self.started = true
    self.save

    #Submit job to delayed_job
    delayed_job_object = ar_module.delay.submit_job(self, options)
    #delayed_job_object = Delayed::Job.enqueue self
    delayed_job_object.job_id = self.id
    delayed_job_object.save
  end


  def submit_job_threads(ar_module, options)
 	  self.started = true
    self.save

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
    self.save

  	return true
  end
end
