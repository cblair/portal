module DocumentsHelper
  require 'csv'
  require 'zip/zipfilesystem'
  require 'open-uri'
  require 'json'
  require 'cgi'
  include IfiltersHelper
  include CouchdbHelper

  #helpers for testing devise
  #if Rails.env.test?
  #  include Devise::TestHelpers
  #end


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

    #TODO: replace all back slashes with forward slashes
    
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
  def save_file_to_document(fname, file, c, f, user=current_user)
    status = false

    if (fname == nil or file == nil)
      log_and_print "WARN: file name or object was nil, can't save to document"
      return false
    end

    @opened_file = File.open file
    
    stime = Time.now()
    
    #Save Document
    @document=Document.new
    @document.name=fname
    @document.collection=c
    @document.stuffing_text = @opened_file.read()
    @document.user = user

    begin
      status = @document.save
      etime = Time.now()
      log_and_print "INFO: Saved document #{fname} in #{etime - stime} seconds."
    rescue RestClient::Conflict
      log_and_print "ERROR: 409 Conflict, couldn't save document. ActiveRecord and CouchDB databases may be out of sync."
      return false
    rescue RestClient::ResourceNotFound
      log_and_print "ERROR: 404, couldn't save document. ActiveRecord and CouchDB databases may be out of sync."
      return false
    rescue RestClient::BadRequest
      log_and_print "ERROR: Couldn't save document #{fname}, probably because of a parse error."

      log_and_print "ERROR: More parse information: "
      log_and_print @document.stuffing_text
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

    if iterator.class == String
      #spilt the iterator text by endlines
      iterator = iterator.split(/$/)
    #else if iterator.class == File (or anything else), do nothing
    end

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

    #CSV
    if (f != nil and f['id'] == -1)
      return filter_data_columns_csv(iterator)
    end

    #XML
    if (f != nil and f['id'] == -2)
      return filter_data_columns_xml(iterator)
    end
    
    #TODO: cleanup
    #get the column names
    #TODO: just setting to [1] for now
    colnames = [1]

    rows = []
    if iterator.class == String
      rows = iterator.split(/$/)
    elsif iterator.class == File
      rows = iterator
    end

    data_columns=[]
    i = 0
    rows.each do |row|
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


  def filter_data_columns_csv(iterator)
    retval = []

    if iterator == nil
      return []
    end

    rows = CSV.parse(iterator)

    colnames = rows.first

    (2..rows.length - 1).each do |i|
      row = Hash[[colnames, rows[i]].transpose]
      retval << row
    end

    return retval
  end


  def filter_data_columns_xml(iterator)
    data_text = iterator

    #the hash of the entire xml tree
    xml_hash = Hash.from_xml(data_text)

    #the return data
    data = []

    if xml_hash != nil
      #get the first thing that is a list in the xml "dataroot" element
      table_data = []
      xml_hash["dataroot"].each {|datum| table_data = datum if datum.kind_of? Array }
      #the first element is usually named after the table. Get the next element (usually
      # the second) that is a list
      table_data.each {|datum| data = datum if datum.kind_of? Array }
      if data.empty?
        log_and_print "WARN: XML filtered data was empty. Reverting filter"
      end
    end

    data
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
      log_and_print "WARN: get_document_metadata threw an unknown exception"
       md = []
    end

    if md == nil
      md = []
    end
    
    return md
  end


  #Gets stuffing data, catching exception if doc metadata dne
  def get_document_data(doc)
    d = []
    begin
      d = doc.stuffing_data
    rescue
      log_and_print "WARN: get_document_data threw an unknown exception"
      d = []
    end
    
    return d
  end


  def get_last_n_above_id(d, xname, yname, lastid, max)
      out = []

      if ( (d == nil) or (xname == nil) or (yname == nil) )
        log_and_print "WARN: Calling with Document, x or y name == nil"
        return []
      end

      stuffing_data = get_document_data(d)

      if stuffing_data.empty?
        return []
      end

      lid = lastid.to_i
      last = lid
      stuffing_data.find_all do |item|
          if item["id"] != nil && item["id"] > lid
              out << [item[xname], item[yname]]
              last = item["id"]
          end
      end

      if ((max != nil) and (max >= 0))
        out = out.last(max.to_i)
      else
        out = []
        last = -1
      end

      return {"lastpt" => last, "points" => out}
  end
  
  #Gives the count of every value in a column
  def get_data_map(d, colname)
    data_columns = []
    dc = get_data_column(d,colname)

    begin
      dc = dc.group_by(&:capitalize).map {|k,v| {k => v.length}}
    rescue NoMethodError #one of the values wasn't a string, and the capitalize method dne
      dc = dc.group_by(&:to_s).map {|k,v| {k => v.length}}
    end
    
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
  

  #If the collection has any viewable docs or sub-collections
  def collection_is_viewable(col, user)
    retval = false

    if col == nil
      return false
    end
    
    if (col.collections.empty? and col.documents.empty?)
      return true
    end
    
    col.documents.each do |doc|
      if doc_is_viewable(doc, user)
        retval = true
      end
    end
    
    #child collections
    col.collections.each do |child_col|
      if collection_is_viewable(child_col, user)
        retval = true
      end
    end
    
    return retval
  end
  

  def doc_is_viewable(col_or_doc, user)
    retval = false

    if col_or_doc == nil
      return false
    end

    #Note: if both are nil, or actual user is record's user...
    if ((col_or_doc.is_a? Document and col_or_doc.user == nil) or (col_or_doc.user == user))
      retval = true
    end
    
    #if the user is a collaborator
    if (user != nil and user.documents != nil and user.documents.include?(col_or_doc))
      retval = true
    end
    
    if (col_or_doc.is_a? Document and col_or_doc.public)
      retval = true
    end
    
    return retval
  end
  
  
  #Populate doc list hash with temp doc objects
  # returns a hash of {doc_name => temp_doc Tempfile}
  def pop_temp_docs_list(doc_list)
    if doc_list == nil
      return {}
    end

    doc_list.each do |key, val|
      document = key

      csv_data = []

      if (document.stuffing_metadata != nil and document.stuffing_data)
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
      end

      temp_doc = Tempfile.new(document.name)
      temp_doc.write(csv_data)
      temp_doc.rewind #rewind data for zip reading?
      
      doc_list[key] = temp_doc
    end #end for i in doc_list
  
    return doc_list
  end
  
  
  def zip_doc_list(parent_dirs, zipfile, doc_list)
    if (parent_dirs == nil or zipfile == nil or doc_list == nil)
      return false
    end

    doc_list = pop_temp_docs_list(doc_list)
      
    #docs for current dir
    doc_list.each do |doc, temp_doc|
      zipfile.put_next_entry(File.join(parent_dirs | [doc.name]))
      zipfile.print IO.read(temp_doc.path)
      temp_doc.close
    end

    return true
  end

  
  def recursive_collection_zip(parent_dirs, zipfile, collection)
    retval = true #true until a false happens

    if (parent_dirs == nil or zipfile == nil or collection == nil)
      return false
    end

    doc_list = {}
    collection.documents.each do |key|
      doc_list[key] = nil
    end
    
    collection_name = collection.name
    #if collection name is blank, we need some other name
    if collection_name == ""
      collection_name = "(blank)"
    end
    
    retval = ( retval and zip_doc_list(parent_dirs << collection_name, zipfile, doc_list) )
    
    collection.collections.each do |sub_collection|
      retval =  ( retval and recursive_collection_zip(parent_dirs | [sub_collection.name], zipfile, 
                                                      sub_collection)
                )
    end

    return retval
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
      stuffing_metadata = filter_metadata_columns(f, document.stuffing_text)
      stuffing_data = filter_data_columns(f, document.stuffing_text)

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
          #clear out data_text
          document.stuffing_text = nil
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
