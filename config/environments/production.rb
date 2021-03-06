Portal::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  #config.serve_static_assets = false
  config.serve_static_assets = true

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false
  #config.assets.compile = true

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Use a different logger for distributed setups
  # config.logger = SyslogLogger.new

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )
  config.assets.precompile += %w( highcharts.js dataTables/jquery.dataTables )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify
  
  #CouchDB stuff
  #config.couchdb = {
  #                            'COUCHDB_HOST'      => 'app10534904.heroku.cloudant.com',
  #                            'COUCHDB_PORT'      => '443',
  #                            'COUCHDB_USERNAME'  => 'app10534904.heroku',
  #                            'COUCHDB_PASSWORD'  => 'QTRGjtDrQkATkjPuCGUAVUPh',
  #                            'COUCHDB_HTTPS'     => true
  #                 }
  config.couchdb = {
                              'COUCHDB_HOST'      => '127.0.0.1',
                              'COUCHDB_PORT'      => '5984',
                              'COUCHDB_USERNAME'  => '',
                              'COUCHDB_PASSWORD'  => '',
                              'COUCHDB_HTTPS'     => false
                   }

  # localhost is default dev url
  #config.action_mailer.default_url_options = { :host => 'peaceful-lake-8763.herokuapp.com' }
  config.action_mailer.default_url_options = { :host => 'www.datahatch.org' }

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

  # Enable threaded mode, unless a rake task (likely Delayed Job) is running:
  config.threadsafe! unless defined?($rails_rake_task) && $rails_rake_task

end
