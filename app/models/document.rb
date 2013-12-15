class Document < ActiveRecord::Base
  include CouchdbHelper
  include DocumentsHelper
  require 'stuffing'
  require 'hatch_custom_exceptions'

  attr_accessible :name, :stuffing_data, :stuffing_search, :stuffing_primary_keys, :stuffing_foreign_keys, :collection_id

  after_initialize :create_default_couchdb
    
  attr_accessible :user_id, :project_id # needed for projects?
  
  belongs_to :collection
  #TODO: not working, server startup. dump?
  #has_and_belongs_to_many :users  #collaborators
  belongs_to :user                #owner
  belongs_to :project
  has_many :charts, :dependent => :destroy
  
  stuffing  :host     => Portal::Application.config.couchdb['COUCHDB_HOST'], 
            :port     => Portal::Application.config.couchdb['COUCHDB_PORT'],
            :username => Portal::Application.config.couchdb['COUCHDB_USERNAME'],
            :password => Portal::Application.config.couchdb['COUCHDB_PASSWORD'],
            :https    => Portal::Application.config.couchdb['COUCHDB_HTTPS']


  def create_default_couchdb
    if (Rails.cache.fetch("document_model_initialized") != true) && is_couchdb_running?(
              host     = Portal::Application.config.couchdb['COUCHDB_HOST'], 
              port     = Portal::Application.config.couchdb['COUCHDB_PORT'],
              username = Portal::Application.config.couchdb['COUCHDB_USERNAME'],
              password = Portal::Application.config.couchdb['COUCHDB_PASSWORD'],
              https    = Portal::Application.config.couchdb['COUCHDB_HTTPS']
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
      end
      if !self.view_exists("row_by_doc_and_data")
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
                                }",
                                "")
      end
      if !self.view_exists("all_rows")
        self.create_simple_view("all_rows",
"function(doc) {
    for(data_i in doc.data) {
       var row = doc.data[data_i];
       emit(doc._id, row);
    }
  }",
"")
      end
      if !self.view_exists("all_row_count")
        self.create_simple_view("all_row_count",
"function(doc) {
    var data_i = 0;
    var count = 0;
    for(data_i in doc.data) {
      count = count + 1;
    }
    emit(doc._id, count);
}",
"")
      end

      #Mark ourselves as initialized.
      Rails.cache.write("document_model_initialized", true)
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
      stuffing_data = filter_data_columns(f, self.stuffing_text, {:document => self})

      #If stuffing_data equals true, then everything is ok, but we don't want to do
      # anything more.
      if stuffing_data == true
        return true
      end

      #Check if filter was successful
      if stuffing_data != nil && stuffing_data != true && !stuffing_data.empty?
        if  (f.stuffing_headers != nil \
             and stuffing_metadata.count == f.stuffing_headers.count)\
            or \
            (f.stuffing_headers == nil)
          validation_finished = true
          self.stuffing_data = stuffing_data
          self.validated = true
          #clear out data_text
          self.stuffing_text = nil

          #Add HatchFilter key => val to metadata
          filter_name = f.name or "none"

          if stuffing_metadata.empty?
            stuffing_metadata = [{"HatchFilter" => filter_name}]
          else
            stuffing_metadata << {"HatchFilter" => filter_name}
          end

          self.stuffing_metadata = stuffing_metadata
          suc_valid = self.save
          
          if suc_valid 
            puts "Document #{self.name} fitering success!"
          end
        end
      end
      
      i = i + 1
      if i >= (ifilters_count)
        validation_finished = true
      end
    end

    
    if !suc_valid
      mcount = f.stuffing_metadata.count if f.stuffing_metadata != nil
      hcount = f.stuffing_headers.count if f.stuffing_headers != nil

      msg = "Document filtering failed. One of these is not right:\n"
      msg += "####metadata:\n"
      msg += "stuffing_metadata.count #{mcount.to_s} ?= f.stuffing_headers.count #{hcount.to_s}\n"
      msg += stuffing_metadata.to_s + "\n"
      msg += "####data:####\n"
      msg += stuffing_data.to_s + "\n"

      raise msg
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
    puts "########################################################"
    puts "Validating doc #{self.name}..."

    self.job_id = job.id
    self.save

    ifilter = get_ifilter(options[:ifilter_id].to_i) or nil

    if !self.validated
      job.succeeded = self.validate(ifilter)

      if job.succeeded
        job.output = "Document validated successfully."
      end
    else
      job.succeeded = true
      job.output = "Document already validated."
    end

    puts job.output
    
    puts "Validating doc #{self.name} complete!"
    puts "########################################################"
    job.finished = true
    job.save
  end
end
