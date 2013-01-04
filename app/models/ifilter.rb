class Ifilter < ActiveRecord::Base
  require 'stuffing'
  
  attr_accessible :name, :regex, :stuffing_headers
  
  stuffing  :host     => ENV['COUCHDB_HOST'], 
            :port     => ENV['COUCHDB_PORT'],
            :username => ENV['COUCHDB_USERNAME'],
            :password => ENV['COUCHDB_PASSWORD'],
            :https    => ENV['COUCHDB_HTTPS'] == 'true'
end
