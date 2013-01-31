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
  gem 'sass-rails'#,   '~> 3.1.5'
  #gem 'therubyracer'
  #gem 'therubyracer', '0.11.0beta5'
  #gem 'libv8', '~> 3.11.8'
  gem 'coffee-rails'#, '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
  gem 'therubyracer', '0.9.9'
  gem 'libv8', '~> 3.3.10'
end

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-fileupload-rails'
gem 'less'
gem 'less-rails'
#this requires the command:
# rails g bootstrap:install
gem 'twitter-bootstrap-rails'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

gem 'lazy_high_charts'

gem 'couchrest'
gem 'stuffing', :git => "git://github.com/cblair/stuffing.git", :branch => "integration"

gem 'devise', '~> 2'

gem 'will_paginate'#, '3.0.pre2'

gem 'rufus-scheduler'

#Only for development
group :development do
  gem 'debugger'
  gem "ruby-prof"
  gem 'simplecov', :require => false, :group => :test
  #gem 'rack-mini-profiler'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'meta_request'

  #  OSX Lion wants this fix for Ruby 1.9.3:
  #   https://github.com/chuckg/chuckg.github.com/blob/master/ruby/193_and_rdebug.md
  #  TODO: Probably want this for other versions of Mac/Linux too.
  if RUBY_PLATFORM == 'x86_64-darwin11.3.0'
    #gem 'debugger'
    #gem 'rack-mini-profiler'
  else
    #Ubuntu 11.10 likes this. ?
    #gem 'ruby-debug', :platforms => :ruby_18
    #gem 'ruby-debug19', :platforms => :ruby_19
  end
end

#Rubyzip
gem 'rubyzip'

#Paperclip
gem "paperclip", "~> 3.0"

#Spawn - for forking processing
gem "spawn", :git => 'git://github.com/rfc2822/spawn'

#New Relic
gem 'newrelic_rpm'
