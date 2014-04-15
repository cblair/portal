class Job < ActiveRecord::Base
  require 'spawn'
  require 'delayed_job_runner'

  attr_accessible :description, :finished, :user_id

  belongs_to :user
  has_one :delayed_job

  def submit_job(current_user, ar_module, options)
    jobs = Job.where(:user_id => current_user.id)
    if jobs.count > 1000
      puts "WARN: user #{current_user.email} has exceeded maximum jobs"
      return false
    end

    self.user = current_user
    self.waiting = true

    job_type = Portal::Application.config.job_type
    #job_type = "threads" #SAS

    if job_type == "threads"
      self.submit_job_threads(ar_module, options)
    elsif job_type == "delayed_job"
      self.submit_job_delayed_job(ar_module, options)
    end
  end  

  ##############################################################################
  ##  Jobs - thread mode functions (obsolete)
  ##############################################################################
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
          #If ar_module is a doc, gets passed to "submit_job" in doc model?
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

  ##############################################################################
  ##  Jobs - Delayed Job mode functions (current)
  ##############################################################################
  def submit_job_delayed_job(ar_module, options)
    self.started = true
    self.save

    #Submit job to delayed_job
    puts "INFO: Starting DelayedJobRunner on #{ar_module.class.name}..."
    #Typical submit...
    #delayed_job_object = ar_module.delay.submit_job(self, options)
    #~OR, using enqueue...
    delayed_job_object = Delayed::Job.enqueue DelayedJobRunner.new(self, ar_module, options)

    delayed_job_object.job_id = self.id
    delayed_job_object.save
  end

  ##############################################################################
  ##  Other helpers
  ##############################################################################

  #Makes job text displayable for the web
  def safe_html(key)
    s = self[key]

    if s != nil
      #drop <> chars 
      s = s.gsub(/[<>]/, '')
      #turn newlines into breaks
      s = s.gsub(/\n/, '<br />')
    else
      s = ""
    end
    
    s
  end

  def get_error_or_output
    retval = ""

    if self.last_error
      retval = self.safe_html(:last_error)
    else
      retval = self.safe_html(:output)
    end

    retval
  end
end
