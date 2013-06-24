Portal::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = false
  
  #CouchDB stuff
  config.couchdb = {
                              'COUCHDB_HOST'      => '127.0.0.1',
                              'COUCHDB_PORT'      => '5984',
                              'COUCHDB_USERNAME'  => '',
                              'COUCHDB_PASSWORD'  => '',
                              'COUCHDB_HTTPS'     => false
                   }
  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # localhost is default dev url
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }

  config.action_mailer.delivery_method = :smtp
  #config.action_mailer.default_charset = "utf-8"
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.smtp_settings = {
       :authentication => :plain,
       :address => "smtp.mailgun.org",
       :port => 587,
       :domain => "app10534904.mailgun.org",
       :user_name => "postmaster@app10534904.mailgun.org",
       :password => "2dlgq3hgb4w3"
  }

  #Jobs stuff
  config.job_type = "delayed_job"
end
