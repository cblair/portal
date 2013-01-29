module DocumentsHelper
  require 'csv'
  require 'zip/zipfilesystem'
  include IfiltersHelper

  #helpers for testing devise
  if Rails.env.test?
    include Devise::TestHelpers
  end


  def is_json?(str)
    begin
      JSON.parse str
    rescue JSON::ParserError
      logger.info "Failed is_json?, ParserError"
      return false
    rescue
      logger.info "Failed is_json? for unknown reason"
      return false
    end

    return true
  end


  def log_and_print(str)
    logger.info str
    puts str
  end

  # @param zip_fname A string of the zip file name
  # @param zip_file_object A file object for the zip file
  # @param user_c A Collection object
  # @param f A IFilter object
  def save_zip_to_documents(zip_fname, zip_file_object, user_c, f, user=current_user)
    #true until something fails
    status = true

    if (zip_fname == nil or zip_file_object == nil)
      log_and_print "WARN: zip file name or zip file object was nil"
      return false
    end

    #TODO: replace all back slagshes with forward slashes
    
    #a dictionary of dircetories, than point to collections 
    zip_collections = {}
          
    #Zip::ZipFile.open(zip_file_object.tempfile) do |zipfile|
    Zip::ZipFile.open(zip_file_object.upfile.path) do |zipfile|
      zipfile.each do |file|
        fname = file.name
        basename = File.basename(fname)
          
        if file.directory?
          #strip trailing slashes
          if fname[fname.length-1] == '/' or fname[fname.length-1] == '\''
            fname = fname[0..fname.length-2]
          end
          
          c = Collection.new( :name => basename, 
                              :collection => zip_collections[File.dirname(fname)])
          c.user = user
          c.save
          
          #save to collections dictionary
          zip_collections[fname] = c
        else
          log_and_print "Processing document '#{fname}'..."
          tempfile = File.new('/tmp/' + basename, 'w')
          tempfile.binmode
          tempfile.write file.get_input_stream.read
          tempfile.rewind
          tempfile.close
          
          c_name = File.dirname(fname)
          status = status and save_file_to_document(basename, tempfile, zip_collections[c_name], f, user)
        end
      end
    end
    
    #put all parentless zip collections under the user_c
    zip_collections.keys.each do |k|
      c = zip_collections[k]
      if c.collection == nil
        c.collection = user_c

        status = (c.save and status)
      end
    end

    return status
  end
   
   
  #save a file from a web upload to an db doc
  # 
  # @param fname A string of the file name
  # @param c A Collection object
  # @param f A IFilter object
  # @param p A project object
  #def save_file_to_document(fname, file, c, f, p)
  def save_file_to_document(fname, file, c, f, user=current_user)
    status = false

    if (fname == nil or file == nil)
      log_and_print "WARN: file name or object was nil, can't save to document"
      return false
    end

    stime = Time.now()

    #csv import. Each call on @parsed_file.<method> increments the cursor
    #begin
      #@opened_file=CSV::CSV.open(file)
      @opened_file = File.open file
    #rescue
    #  return false #unsupported file type
    #end
    
    #get filtered headers, put them in metadata
    metadata_columns = filter_metadata_columns(f, @opened_file)
        
    data_columns= filter_data_columns(f,@opened_file)

    etime = Time.now()
    
    log_and_print "Filtered document #{fname} in #{etime - stime} seconds."
    
    stime = Time.now()
    
    #Transform all values to native ruby types
    #TODO: do we really need this with the CouchDB storage?
    #      also, optimize before enabling
    #data_columns=convert_data_to_native_types(data_columns)
    
    etime = Time.now()
    
    #logger.info "Converted document #{fname} data in #{etime - stime} seconds."
    
    stime = Time.now()
    
    #Save Document
    @document=Document.new
    @document.name=fname
    @document.collection=c
    #@document.project=p		#links document to project
    @document.stuffing_data=data_columns
    @document.stuffing_metadata=metadata_columns
    @document.user = user

    begin
      status = @document.save
      etime = Time.now()
      log_and_print "INFO: Saved document #{fname} in #{etime - stime} seconds."
    rescue RestClient::Conflict
      log_and_print "ERROR: 409 Conflict, couldn't save document. ActiveRecord and CouchDB databases may be out of sync."
      return false
    rescue RestClient::BadRequest
      log_and_print "ERROR: Couldn't save document #{fname}, probably because of a parse error."

      dc_is_valid_json = is_json?(data_columns.to_s)
      mdc_is_valid_json = is_json?(metadata_columns.to_s)

      log_and_print "ERROR: More parse information: "
      log_and_print "ERROR:  is data json?: #{dc_is_valid_json}"
      log_and_print "ERROR:  is metadata json?: #{mdc_is_valid_json}"
      return false
    end

    @opened_file.close

    return status
  end
  

  def get_data_colnames(d)
    if d == nil or d.empty?
      return []
    end
    return d.first().keys()
  end
  
  
  def filter_metadata_columns(f, iterator)
    metadata_columns = []
    if f != nil and iterator != nil
      i = 0
      get_ifilter_headers(f).each do |h|
        metadata_col_hash = {}
        
        begin
          row = iterator[i]
        rescue
          row = []
          log_and_print "WARN: filter_metadata_columns() is parsing empty data"
        end
        
        #if row is a hash (i.e. from a Couchdb doc and not a Tempfile),
        # join it back into one string
        if row.is_a? Hash
          row = row.map {|k,v| v}.join
        end
        
        row = get_ifiltered_header(h, row)
        
        colnames = get_ifiltered_colnames(row)
        
        for j in (0..row.count-1)
          metadata_col_hash[ colnames[j] ] = row[j]
        end
        
        if not metadata_col_hash.empty?
          metadata_columns << metadata_col_hash
        end

        i = i + 1 
      end
    else
      metadata_columns = []
    end
    
    return metadata_columns
  end
  
  
  def filter_data_columns(f, iterator)
    if iterator == nil
      log_and_print "WARN: data iterator was nil"
      return []
    end
    
    #TODO: cleanup
    #get the column names
    colnames=[]
    if false
      colnames = iterator.first() #gets the next row, increments the iterator
    else
      colnames = [1]
    end
    
    data_columns=[]
    i = 0
    iterator.each do |row|
      data_col_hash = {}
      
      #apply input filters
      if f != nil
       #if row is a hash (i.e. from a Couchdb doc and not a Tempfile),
       # join it back into an Array
       if row.is_a? Hash
        row = row.map {|k,v| v}
       end
        
       #overwrite row with filtered row
       row = get_ifiltered_row(f, row)
       #overwrite col names with numbered colnames
       
       colnames = get_ifiltered_colnames(row)
      else
        row = [row]
      end
      
      for j in (0..row.count() - 1)
        data_col_hash[ colnames[j] ] = row[j]
      end

      data_columns << data_col_hash  
    end

    data_columns.reject! { |item| item.empty? }
    return data_columns
  end
  

  #Returns an Array of Hashes with only the key => value pairs where key == colname
  #
  # @param d A Document object
  # @param colname A string for the desired colname
  #
  def get_data_column(d, colname)
    dc = []

    if (d == nil or d.stuffing_data == nil)
      log_and_print 'WARN: Request for document data column with either a nil document or nil stuffing data'
      return []
    end

    d.stuffing_data.find_all do |item| 
      if item[colname] != nil 
        dc << item[colname] 
      end
    end
    return dc
  end


  #Gets stuffing metadata, catching exception if doc metadata dne
  def get_document_metadata(d)
    md = []
    begin
      md = d.stuffing_metadata
    rescue
       md = []
    end
    
    return md
  end


  def get_last_n_above_id(d, xname, yname, lastid, max)
      out = []
      document = Document.find(d)
      lid = lastid.to_i
      last = lid
      document.stuffing_data.find_all do |item|
          if item["id"] != nil && item["id"] > lid
              out << [item[xname], item[yname]]
              last = item["id"]
          end
      end
      out = out.last(max.to_i)
      return {"lastpt" => last, "points" => out}
  end
  
  #Gives the count of every value in a column
  def get_data_map(d, colname)
    data_columns = []
    dc=get_data_column(d,colname)
    dc = dc.group_by(&:capitalize).map {|k,v| {k => v.length}}
    
    dc.each do |row|
      data_col_hash = {}
      colnames = ["value","count"]
      key = row.keys().first()
      data_col_hash["value"] = key
      data_col_hash["map"] = row[key]
      data_columns << data_col_hash
    end

    return data_columns
  end
  
  
  def document_search_data(search)
    #view
    retval = []
    
    Document.all().each do |doc|
      #TODO: define search doc name globally
      if doc.stuffing_data != [] and doc.name != "temp_search_doc"
        matches = []
        #matches = doc.stuffing_data.select {|row| row.values {|value| value =~ search } }
        doc.stuffing_data.each do |row|
            found = false 
            row.values.each do |value|
              if value =~ /#{search}/
                found = true
              end
            end
            if found == true
              matches << row
            end
        end
        
        if matches != []
          matches.each {|row| retval << row}
        end
      end
    
      end
  end

  def document_search_data_couch(search, lucky_search = false)
    #Use any Document instance to access the Stuffing view method
    #If exact value searched for, call key view
    if lucky_search == false
      docs = Document.first().view("all_data_values/view1", {:startkey => search})["rows"]
    #Otherwise, call startkey - endkey view
    else
      docs = Document.first().view("all_data_values/view1", {:key => search})["rows"]
    end
    
    #Compile the resulting data back into a record-like array of hashes
    retval = []
    docs.each do |doc|
      retval << doc["value"]
    end
    
    return retval
  end
  
  #If the collection has any viewable docs or sub-collections
  def collection_is_viewable(col)
    retval = false
    
    if (col.collections.empty? and col.documents.empty?)
      return true
    end
    
    col.documents.each do |doc|
      if doc_is_viewable(doc)
        retval = true
      end
    end
    
    #child collections
    col.collections.each do |child_col|
      if collection_is_viewable(child_col)
        retval = true
      end
    end
    
    return retval
  end
  
  def doc_is_viewable(col_or_doc)
    retval = false
    
    #Note: if both are nil, or actual user is record's user...
    if (col_or_doc.user == nil) or (col_or_doc.user == current_user)
      retval = true
    end
    
    #if the user is a collaborator
    if current_user != nil and current_user.documents != nil and current_user.documents.include?(col_or_doc)
      retval = true
    end
    
    if col_or_doc.is_a? Document and col_or_doc.public
      retval = true
    end
    
    return retval
  end
  
  
  #Populate doc list hash with temp doc objects
  # returns a hash of {doc_name => temp_doc Tempfile}
  def pop_temp_docs_list(doc_list)
    doc_list.each do |key, val|
      document = key
      @headings = document.stuffing_data.first.keys
  
      csv_data = CSV.generate do |csv|
          #Metadata
          document.stuffing_metadata.each do |row|
            csv << row.values
          end
          
          #Data headings
          # if there is only one column named "1", its the default column for
          # a unfiltered document. Ignore the column.
          if !(@headings.length == 1 and @headings[0] == "1")
            csv << @headings
          end
          
          #Data
          document.stuffing_data.each do |row|
              csv << row.values
          end
      end
  
      temp_doc = Tempfile.new(document.name)
      temp_doc.write(csv_data)
      temp_doc.rewind #rewind data for zip reading?
      
      doc_list[key] = temp_doc
    end #end for i in doc_list
  
    return doc_list
  end
  
  
  def zip_doc_list(parent_dirs, zipfile, doc_list)
    doc_list = pop_temp_docs_list(doc_list)
      
    #docs for current dir
    doc_list.each do |doc, temp_doc|
      zipfile.put_next_entry(File.join(parent_dirs | [doc.name]))
      zipfile.print IO.read(temp_doc.path)
      temp_doc.close
    end
  end

  
  def recursive_collection_zip(parent_dirs, zipfile, collection)
    doc_list = {}
    collection.documents.each do |key|
      doc_list[key] = nil
    end
    
    collection_name = collection.name
    #if collection name is blank, we need some other name
    if collection_name == ""
      collection_name = "(blank)"
    end
    
    zip_doc_list(parent_dirs << collection_name, zipfile, doc_list)
    
    collection.collections.each do |sub_collection|
      recursive_collection_zip(parent_dirs | [sub_collection.name], zipfile, 
                              sub_collection)
    end
  end
  
  
  def validate_document_helper(document, ifilter=nil)
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
      stuffing_metadata = document.stuffing_metadata
      stuffing_data = document.stuffing_data
      
      f = ifilters[i]
      
      #Attempt filter
      stuffing_metadata = filter_metadata_columns(f, stuffing_data)
      stuffing_data = filter_data_columns(f, stuffing_data)

      #Check if filter was successfu=l
      if stuffing_data != nil and not stuffing_data.empty?
        if  (f.stuffing_headers != nil \
             and stuffing_metadata.count == f.stuffing_headers.count)\
            or \
            (f.stuffing_headers == nil and stuffing_metadata.empty?)
          validation_finished = true
          document.stuffing_metadata = stuffing_metadata
          document.stuffing_data = stuffing_data
          document.validated = true
          suc_valid = document.save
        end
      end
      
      i = i + 1
      if i >= (ifilters_count)
        validation_finished = true
      end
    end
    
    return suc_valid
  end
end
