# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Portal::Application.initialize!

#ENV['RAILS_ENV'] ||= 'development'
ENV['RAILS_ENV'] ||= 'production'

ENV['temp_search_doc'] = "temp_search_doc"

#Newrelic barking
STDOUT.puts "RPM detected environment: #{NewRelic::LocalEnvironment.new}"#, RAILS_ENV: #{RAILS_ENV}"
