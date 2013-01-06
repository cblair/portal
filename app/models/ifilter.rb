class Ifilter < ActiveRecord::Base
  require 'stuffing'
  
  attr_accessible :name, :regex, :stuffing_headers
  
  stuffing  :host     => Portal::Application.config.couchdb['COUCHDB_HOST'], 
            :port     => Portal::Application.config.couchdb['COUCHDB_PORT'],
            :username => Portal::Application.config.couchdb['COUCHDB_USERNAME'],
            :password => Portal::Application.config.couchdb['COUCHDB_PASSWORD'],
            :https    => Portal::Application.config.couchdb['COUCHDB_HTTPS']
end
