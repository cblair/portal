class Document < ActiveRecord::Base
  include CouchdbHelper
  include DocumentsHelper
  require 'stuffing'

  attr_accessible :name, :stuffing_data, :stuffing_search, :stuffing_primary_keys, :stuffing_foreign_keys, :collection_id

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


  def validate(ifilter=nil)
    #Try to filter until successful or 
    # either successfully filtered or are out of filters
    validation_finished = false
    suc_valid = false
    
    if ifilter == nil
      ifilters = Ifilter.all
      ifilters_count = ifilters.count
    else
      ifilters = [ifilter]
      ifilters_count = 1
    end

    #filter index
    i = 0
    while validation_finished == false
      #copy these so filter attempts don't overwrite the original data
      stuffing_metadata = self.stuffing_metadata
      stuffing_data = self.stuffing_data
      
      f = ifilters[i]
      
      #Attempt filter
      stuffing_metadata = filter_metadata_columns(f, self.stuffing_text)
      stuffing_data = filter_data_columns(f, self.stuffing_text)

      debugger
      #Check if filter was successfu=l
      if stuffing_data != nil and not stuffing_data.empty?
        if  (f.stuffing_headers != nil \
             and stuffing_metadata.count == f.stuffing_headers.count)\
            or \
            (f.stuffing_headers == nil and stuffing_metadata.empty?)
          validation_finished = true
          self.stuffing_metadata = stuffing_metadata
          self.stuffing_data = stuffing_data
          self.validated = true
          #clear out data_text
          self.stuffing_text = nil
          suc_valid = self.save
        end
      end
      
      i = i + 1
      if i >= (ifilters_count)
        validation_finished = true
      end
    end

    self.stuffing_foreign_keys = get_foreign_keys(self, ifilter)

    #Add primary keys
    #@document.stuffing_primary_keys = params[:primary_keys]
    #Hack for now - add all column keys to primary keys for search
    self.stuffing_primary_keys = get_data_colnames(self.stuffing_data)

    self.save
    
    return suc_valid
  end


  def submit_job(job, options)
    ifilter = options[:ifilter] or nil
    
    puts "########################################################"
    puts "Validating doc #{self.name}..."
    self.validate(ifilter)
    
    puts "Validating doc #{self.name} complete!"
    puts "########################################################"
    job.finished = true
    job.save
  end
end
