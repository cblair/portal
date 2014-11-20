class Document < ActiveRecord::Base
  include CouchdbHelper
  include DocumentsHelper
  include SearchesDatatableHelper
  include SearchesHelper
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
  belongs_to :job
  
  stuffing  :host     => Portal::Application.config.couchdb['COUCHDB_HOST'], 
            :port     => Portal::Application.config.couchdb['COUCHDB_PORT'],
            :username => Portal::Application.config.couchdb['COUCHDB_USERNAME'],
            :password => Portal::Application.config.couchdb['COUCHDB_PASSWORD'],
            :https    => Portal::Application.config.couchdb['COUCHDB_HTTPS']


  def create_default_couchdb
    #TODO: since moving to couchdb 1.5.0, we're moving away from couchdb views.
    # So most of this method will go away.
    return

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
    message = "" 
    
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
      curr_md = self.stuffing_metadata ||= [] # for existing MD from a metaform
      stuffing_data = self.stuffing_data

      f = ifilters[i]

      #Attempt filter
      stuffing_metadata = filter_metadata_columns(f, self.stuffing_text)
      #stuffing_data = filter_data_columns(f, self.stuffing_text, {:document => self})
      retval_arr = filter_data_columns(f, self.stuffing_text, {:document => self})
      stuffing_data = retval_arr[1]
      message = retval_arr[0]

      #If stuffing_data equals true, then everything is ok, but we don't want to do
      # anything more.
      if stuffing_data == true
        puts message
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
          self.stuffing_text = nil  #clear out data_text

          #Add HatchFilter key => val to metadata
          filter_name = f.name or "none"

          if stuffing_metadata.empty?
            stuffing_metadata = [{"HatchFilter" => filter_name}]
          else
            stuffing_metadata << {"HatchFilter" => filter_name}
          end

          #stores new and pre-existing metadata (from metaform)
          self.stuffing_metadata = stuffing_metadata + curr_md
          suc_valid = self.save
          
          if suc_valid
            puts "### Document #{self.name} fitering success! ###"
            upload_remove_on_validate(self)  #Deletes upload after successful validation.
          end
        end

      elsif stuffing_data == nil
        puts "#### Error: there was a problem filtering ####"
        validation_finished = true
        suc_valid = false
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
      msg += message
      msg += "####metadata:\n"
      msg += "stuffing_metadata.count #{mcount.to_s} ?= f.stuffing_headers.count #{hcount.to_s}\n"
      msg += stuffing_metadata.to_s + "\n"
      msg += "####data:####\n"
      msg += stuffing_data.to_s + "\n"

      puts msg
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


  def create_merge_search_document(search, view, current_user)
    #Set up our view context so we can delegate merge search stuff.
    @view = view

    #Get doc list, so we can get colnames in common
    options =   {
                  #set the ES from (search offset) field from the last doc search
                  :from => doc_search_page,
                  #set the ES size (how many from search offset) field from the last doc search
                  # per_page method
                  :size => doc_search_per_page
                }

    options[:flag] = 'f'
    results = ElasticsearchHelper::es_search_dispatcher("es_query_string_search", search, options)

    doc_list = get_docs_from_raw_es_data(results, current_user)
    colnames = []

    #Don't let unvalidated docs screw up the search results
    validated_doc_list = doc_list.reject {|doc| !doc.validated }
    if !validated_doc_list.empty?
      colnames = get_colnames_in_common(validated_doc_list)
    end

    raw_data = results

    doc_data = []
    if raw_data
      #Set the total documents found in the results, in case we later
      # determine that we only have document results and the return
      # data is already paginated from ES, so a data.count would be
      # wrong
      @document_count = ElasticsearchHelper.get_document_count

      raw_data.collect do |row|
        doc_name = row["_source"]["_id"]
        score = row["_score"]
        doc_id = doc_name.sub("Document-", "").to_i

        begin
          doc = Document.find(doc_id)
        rescue ActiveRecord::RecordNotFound
          log_and_print "WARN: Document with id #{doc_id} not found in search. Skipping."
          #better decrement our document_count for the results
          next
        end

        #Only merge in data that this user can view, even though SearchAllDatable would
        # show them any and every doc's metadata
        if doc_is_viewable(self, current_user)
          colnames_in_common_and_merge_search =  (!colnames.empty?) && (merge_search)
          if colnames_in_common_and_merge_search && doc.validated
            row["_source"]["data"].map do |data_row| 
              doc_data << data_row
            end #end row...map
          end #end if doc.validated
        end #end if doc_is_viewable
      end #end raw_data.collect
    end #end raw_data

    c = Collection.find_or_create_by_name(:name => "From Merged Search")
    c.user_id = current_user.id
    c.save
    self.collection = c
    self.stuffing_data = doc_data
    self.user_id = current_user.id
  end


  def validate_document_with_job(job, options)
    puts "########################################################"
    puts "Validating doc #{self.name}..."

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
  end


  def merge_search_with_job(job, options)
    puts "########################################################"
    puts "Merging doc #{self.name}..."

    #Get the original search query.
    search = params["searchval"]

    #We assume the user to merge with is the user that submitted the job
    current_user = job.user

    #Get the params

    #Do the merge.
    self.create_merge_search_document(search, @view, current_user)

    #If we made it this far, all is well.
    job.succeeded = true
    job.output = "Document merged successfully."

    puts "Merging doc #{self.name} complete!"
    puts "########################################################"
  end


  def submit_job(job, options)
    #Save params from original web request.
    self.stuffing_params = options[:params]

    self.job_id = job.id
    self.save

    if options[:mode] == :merge_search
      merge_search_with_job job, options
    else
      validate_document_with_job job, options
    end

    job.finished = true
    job.save
  end


  #Return saved params from original web request, usually for a Job.
  # Used implicitly by a lot of (seach) helpers who normally would
  # see this global set by view_context
  def params
    self.stuffing_params
  end
end
