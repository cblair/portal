Delayed::Worker.sleep_delay = 30
Delayed::Worker.max_attempts = 3
Delayed::Worker.logger = Logger.new(File.join(Rails.root, 'log', 'hatch_delayed_job.log'))
Delayed::Worker.destroy_failed_jobs = false 