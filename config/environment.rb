# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Portal::Application.initialize!

ENV['RAILS_ENV'] ||= 'development'

require 'lazy_high_charts'
