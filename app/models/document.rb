class Document < ActiveRecord::Base
  include CouchdbHelper
  require 'stuffing'

  attr_accessible :name, :stuffing_data, :stuffing_search

  after_initialize :create_default_couchdb
    
  belongs_to :collection
  #TODO: not working, server startup. dump?
  #has_and_belongs_to_many :users  #collaborators
  belongs_to :user                #owner
  has_many :charts, :dependent => :destroy
  
  stuffing  :host     => Portal::Application.config.couchdb['COUCHDB_HOST'], 
            :port     => Portal::Application.config.couchdb['COUCHDB_PORT'],
            :username => Portal::Application.config.couchdb['COUCHDB_USERNAME'],
            :password => Portal::Application.config.couchdb['COUCHDB_PASSWORD'],
            :https    => Portal::Application.config.couchdb['COUCHDB_HTTPS']
  

  def create_default_couchdb()

    if is_couchdb_running?(
              host     = Portal::Application.config.couchdb['COUCHDB_HOST'], 
              port     = Portal::Application.config.couchdb['COUCHDB_PORT'],
              username = Portal::Application.config.couchdb['COUCHDB_USERNAME'],
              password = Portal::Application.config.couchdb['COUCHDB_PASSWORD'],
              https    = Portal::Application.config.couchdb['COUCHDB_HTTPS']
      )
      if !self.view_exists("all_data_values")
        self.create_simple_view("all_data_values", 
        "function(doc) 
          {
            if (doc.data && !doc.is_search_doc)
            {
              for(row_key in doc.data)
              {
                row = doc.data[row_key];
                for(col_key in row)
                {
                  emit(row[col_key], row);
                }
              }
            }
          }")
      end
    end
  end


  #Search for document names
  def self.search(search)
    if search
      where('name LIKE ?', "%#{search}%")
    else
      scoped
    end
  end
end
