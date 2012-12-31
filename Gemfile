source 'http://rubygems.org'

gem 'rails', '3.1.3'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

#gem 'sqlite3', '>= 1.3.1', :require => 'sqlite3'
gem 'pg'

gem 'json'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.1.5'
  #gem 'therubyracer'
  #gem 'therubyracer', '0.11.0beta5'
  #gem 'libv8', '~> 3.11.8'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier', '>= 1.0.3'
  #gem 'jquery-datatables-rails', github: 'rweng/jquery-datatables-rails'
  #gem 'jquery-datatables-rails'#, :git => 'https://github.com/rweng/jquery-datatables-rails.git'
  
  gem 'less'
  gem 'less-rails'
  gem 'therubyracer', '0.9.9'
  gem 'libv8', '~> 3.3.10'
end

gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-fileupload-rails'
gem 'twitter-bootstrap-rails'

#this requires the command:
# rails g bootstrap:install

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
#  OSX Lion wants this fix for Ruby 1.9.3:
#   https://github.com/chuckg/chuckg.github.com/blob/master/ruby/193_and_rdebug.md
#  TODO: Probably want this for other versions of Mac/Linux too.
if RUBY_PLATFORM == 'x86_64-darwin11.3.0'
  #gem 'ruby-debug19', :require => false
  #gem 'ruby-debug-base19', :git => 'https://github.com/tribune/ruby-debug-base19.git', :require => false
  #gem 'linecache19', :git => 'git@github.com:chuckg/linecache19.git', :branch => "0_5_13/dependencies", :require => false
  #gem 'rack-mini-profiler'
else
  #Ubuntu 11.10 likes this. ?
  #gem 'ruby-debug', :platforms => :ruby_18
  #gem 'ruby-debug19', :platforms => :ruby_19
end

#gem 'lazy_high_charts', '~> 1.1.5'
gem 'lazy_high_charts'

gem 'couchrest'
#also, you will need to run this afterward... don't know if it is in a gem yet
#TODO: make a script I guess
#rails plugin install git://github.com/cblair/stuffing.git
gem 'stuffing', :git => "git://github.com/cblair/stuffing.git", :branch => "integration"

gem 'devise', '~> 2'

gem 'will_paginate', '3.0.pre2'

gem 'rufus-scheduler'

#Profiling -- only for development
group :development do
    gem "ruby-prof"
end

#Rubyzip
gem 'rubyzip'

#Paperclip
gem "paperclip", "~> 3.0"

#Spawn - for forking processing
gem "spawn", :git => 'git://github.com/rfc2822/spawn'