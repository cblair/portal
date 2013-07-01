source 'http://rubygems.org'

gem 'rails', '3.2.11'
ruby '1.9.3'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'pg'

gem 'json'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  #don't put twitter-bootstrap-rails here - breaks on Heroku

  gem 'sass-rails'#,   '~> 3.1.5'
  gem 'coffee-rails'#, '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'

  gem 'jquery-rails'
  gem 'jquery-ui-rails'
  gem 'jquery-fileupload-rails', '0.4.0'

  gem 'therubyracer', '0.9.9'
  gem 'libv8', '~> 3.3.10'

  gem 'lazy_high_charts'

  gem 'd3_rails'
end

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-fileupload-rails', '0.4.0'
gem 'd3_rails'
gem 'lazy_high_charts'

gem 'jquery-datatables-rails', github: 'rweng/jquery-datatables-rails'


gem 'less'

gem "less-rails" #Sprockets (what Rails 3.1 uses for its asset pipeline) supports LESS
#this requires the command:
# rails g bootstrap:install
gem 'twitter-bootstrap-rails', '2.2.0'

#this requires the command:
# rails g bootstrap:install
#gem 'twitter-bootstrap-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

gem 'couchrest'
gem 'couchrest_model'
gem 'stuffing', :git => "git://github.com/cblair/stuffing.git", :branch => "integration"

gem 'devise'#, '~> 2'

gem 'will_paginate'#, '3.0.pre2'

gem 'rufus-scheduler'

gem 'cancan'

#Only for development
group :development do
  gem 'debugger'
  gem "ruby-prof"
  gem 'simplecov', :require => false, :group => :test
  gem 'rack-mini-profiler'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'
end

#Rubyzip
gem 'rubyzip'

#Paperclip
gem "paperclip", "~> 3.0"

#Spawn - for forking processing
gem "spawn", :git => 'git://github.com/rfc2822/spawn'

#New Relic
gem 'newrelic_rpm'

gem 'ancestry'

#delayed_job stuff
gem 'daemons'
gem 'delayed_job_active_record'
#TODO: not sure if we're going to use this
gem "delayed_job_web"