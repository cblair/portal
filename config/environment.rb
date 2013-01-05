# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Portal::Application.initialize!

#ENV['RAILS_ENV'] ||= 'development'
ENV['RAILS_ENV'] ||= 'production'

ENV['temp_search_doc'] = "temp_search_doc"

=begin
ENV['COUCHDB_HOST'] = '192.168.1.145'
ENV['COUCHDB_PORT'] = '5984'
ENV['COUCHDB_USERNAME'] = 'cblair3'
ENV['COUCHDB_PASSWORD'] = 'SHIhel7'
ENV['COUCHDB_HTTPS'] = 'false'
=end

ENV['COUCHDB_HOST'] = 'app10534904.heroku.cloudant.com'
ENV['COUCHDB_PORT'] = '443'
ENV['COUCHDB_USERNAME'] = 'app10534904.heroku'
ENV['COUCHDB_PASSWORD'] = 'QTRGjtDrQkATkjPuCGUAVUPh'
ENV['COUCHDB_HTTPS'] = 'true'