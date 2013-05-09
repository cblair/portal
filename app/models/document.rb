class Document < ActiveRecord::Base
  include CouchdbHelper
  require 'stuffing'

  attr_accessible :name, :stuffing_data, :stuffing_search, :collection_id

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


  def create_default_couchdb(called_by_init=false)
    if (called_by_init == true and is_couchdb_running?(
              host     = Portal::Application.config.couchdb['COUCHDB_HOST'], 
              port     = Portal::Application.config.couchdb['COUCHDB_PORT'],
              username = Portal::Application.config.couchdb['COUCHDB_USERNAME'],
              password = Portal::Application.config.couchdb['COUCHDB_PASSWORD'],
              https    = Portal::Application.config.couchdb['COUCHDB_HTTPS']
        )
    )
      if !self.view_exists("all_data_values")
        self.create_simple_view("all_data_values", 
                                "function(doc) {
                                  if(doc.primary_keys) {
                                    for(pi in doc.primary_keys) {
                                      var pk = doc.primary_keys[pi];
                                      for(row_i in doc.data) {
                                        var row = doc.data[row_i];
                                        if(row[pk]) {
                                          emit([row[pk]], doc._id);
                                        }
                                      }
                                    }
                                  }
                                }",
                                "function(keys, values) {
                                  retval = {};
                                  for(val_i in values) {
                                    var val = values[val_i];
                                    if(retval[val]) {
                                      retval[val] += 1;
                                    } else {
                                      retval[val] = 1;
                                    }
                                  }
                                  return(retval);
                                }")
        self.create_simple_view("row_by_doc_and_data", 
                                "function(doc) {
                                  if(doc.primary_keys) {
                                    for(pi in doc.primary_keys) {
                                      var pk = doc.primary_keys[pi];
                                      for(row_i in doc.data) {
                                        var row = doc.data[row_i];
                                        //emit([row[pk], pk, doc._id], 1);
                                        //emit([row[pk], pk], 1);
                                        if(row[pk]) {
                                          emit([doc._id, row[pk]], row);
                                        }
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
