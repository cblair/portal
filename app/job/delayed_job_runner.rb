require 'job'

class DelayedJobRunner < Struct.new(:job, :ar_module, :options)
  ##############################################################################
  ##  Delayed Job interface specific hooks
  ##############################################################################
  def perform
    @job = job
    msg = "Calling #{ar_module.class.name}'s submit_job()..."
    puts msg
    Delayed::Worker.logger.debug(msg)
    #Run the active record's submit_job() method, which does the actual work.
    ar_module.submit_job(@job, options)
  end

  def error(delayed_job, exception)
    msg = "ERROR"
    puts msg
    Delayed::Worker.logger.debug(msg)

    @job_failed = true

    if @job != nil
      Delayed::Worker.logger.debug("Job #{@job.id.to_s} error:\n #{exception.inspect}")
      @job.last_error = exception.inspect
    end
    @job.finished = true
    @job.save
  end

  def failure(delayed_job)
    msg = "FAIL"
    puts msg
    Delayed::Worker.logger.debug(msg)

    @job_failed = true

    if @job != nil
      Delayed::Worker.logger.debug("Job #{@job.id.to_s} failed.")
    end
    @job.finished = true
    @job.save
  end

  def after(delayed_job)

  end  
end