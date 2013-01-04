class Document < ActiveRecord::Base
  require 'stuffing'
  attr_accessible :name, :stuffing_data, :stuffing_search
    
  belongs_to :collection
  #TODO: not working, server startup. dump?
  #has_and_belongs_to_many :users  #collaborators
  belongs_to :user                #owner
  has_many :charts, :dependent => :destroy
  stuffing  :host     => ENV['COUCHDB_HOST'], 
            :port     => ENV['COUCHDB_PORT'],
            :username => ENV['COUCHDB_USERNAME'],
            :password => ENV['COUCHDB_PASSWORD'],
            :https    => ENV['COUCHDB_HTTPS'] == 'true'
    
  #Search for document names
  def self.search(search)
    if search
      where('name LIKE ?', "%#{search}%")
    else
      scoped
    end
  end
end
