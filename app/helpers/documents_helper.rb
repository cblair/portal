module DocumentsHelper
  require 'csv'
  require 'zip/zipfilesystem'
  require 'open-uri'
  require 'json'
  require 'cgi'
  require 'filemagic'
  require 'rails_autolink'
  include IfiltersHelper
  include CouchdbHelper
  include HrtHelper
  include UploadsHelper

  #helpers for testing devise
  #if Rails.env.test?
  #  include Devise::TestHelpers
  #end

#-----------------------------------------------------------------------

  #Makes a list of user's note uploads
  def upload_note_select_for_doc
    retval = Upload.where("user_id = ? AND upload_type = ?",
      @document.user_id, "note").order("upfile_file_name").collect { |u| [u.upfile_file_name, u.id] }
  end

  #Adds (links) the current document to the given note file (upload)
  def add_note(upload_id)
    upload = Upload.find(upload_id.to_i)
    
    if not @document.uploads.include?(upload)
      @document.uploads << upload
    end
  end

  #Creates a list of checkboxes for removing notes.
  def remove_note_list()
    remove_upload_ids = []
    @document.uploads.each do |upload|
      remove_upload_ids << upload
    end
    
    return remove_upload_ids
  end
  
  #Removes the link(s) to notes from this document (just the link(s)).
  def remove_notes(remove_list)
    
    remove_list.each do |upload_id|
      upload = Upload.find(upload_id)
      if ( @document.uploads.include?(upload) )
        @document.uploads.delete(upload)
      end
    end
  end

#------------------------------------------------------
  #Gets menu data for display.
  def get_menu
    if (@document == nil)
      return false
    end
    
    @doc_collection = Collection.find(@document.collection_id)
    @raw_file = @document.stuffing_raw_file_url
    
    @job = nil
    if @document.job_id != nil
      begin ActiveRecord::RecordNotFound
        @job = Job.find(@document.job_id)
      rescue
        @job = false
        puts "INFO: Job with id #{@document.job_id} for Document #{@document.name} no longer exists." 
      end
    end
    return true
  end
  
  #Gets info about doc for popup including:
  #1. List of projects this document is in.
  def get_doc_info
    if (@document == nil)
      return false
    end
    
    @collection = Collection.find(@document.collection)
    @project_list = []
    @collection.projects.each do |project|
      @project_list << project
    end
  end
  
  #Gets metadata and sorts it for display
  def get_metadata
    if (@document == nil)
      return false
    end
    
    @msdata = get_document_metadata(@document)
    #md_index = get_md_index() #Gets metadata index for (ace/dec) sorting 
    #sort_metadata(md_index) #Sorts metadata (ace/dec)
  end
  
  #Gets document data from Couch for display.
  def get_show_data
    if (@document == nil)
      return false
    end
    
    @sdata = @document.stuffing_data  #Data from couch
    current_page = params[:page]
    per_page = params[:per_page] # could be configurable or fixed in your app
    
    @paged_sdata = []
    if @sdata != nil
      @paged_sdata = @sdata.paginate({:page => current_page, :per_page => 20})
    end
    
    chart = Chart.find_by_document_id(@document)
    @chart = chart || Chart.find(newchart({:document_id => @document}))
    
    return true
  end

  #Takes metadata from document metadata editor and saves to couch.
  def metadata_save(md_table, document)
    if (document == nil)
      return false
    end
    
    doc_md_new = []          #Array of hashes, stores extracted metadata
    if (md_table == nil)
      doc_md_new = nil
    else
      #Due to the way the table-to-json jQuery plugin forms the json string
      # we need to "decode" the JSON. The plugin uses the column names as
      # keys. For CouchDB we want the 1st value to be the key and the 2nd
      # value to be the value.
      md_fields = md_table["0"].keys #Gets the column names of the metadata table
      labelKey = md_fields[0]  #Actual key from doc MD table
      valKey = md_fields[1]    #Actual value from doc MD table
    
      md_table.each do |key, value|
        md_row = {value[labelKey] => value[valKey]} #Must be "hashified" to save
        doc_md_new << md_row
      end
    end
    
    document.stuffing_metadata = doc_md_new
    document.save
    
    return true
  end
#-----------------------------------------------------------------------

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
    #logger.info str
    puts str
  end
#-----------------------------------------------------------------------

  #Submit a single document validation job
  #Args:  document: document object,  f: filter id,
  def validate_document(document, f)
    #don't let validate auto-filter
    if f != nil
      msg = 'Validation filter started; refresh your browser to check for completion. '

      job = Job.new(:description => "Document #{document.name} validation")
      job.save
      job.submit_job(current_user, document, {:ifilter_id => f.id})
    end
    
    return status, msg
  end
#-----------------------------------------------------------------------

  # @param zip_fname A string of the zip file name
  # @param zip_file_object A file object for the zip file
  # @param user_c A Collection object
  # @param f A IFilter object
  def save_zip_to_documents(zip_fname, zip_file_object, user_c, f, user=current_user)
    #true until something fails
    status = true
    document_id = nil

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
          
          c = Collection.new( :name => basename)#, 
                              #:collection => zip_collections[File.dirname(fname)])
          parent_id = nil
          if zip_collections[File.dirname(fname)] != nil
            parent_id = zip_collections[File.dirname(fname)].id
          end
          c.parent_id = parent_id
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
          retval_status, document_id = save_file_to_document(basename, tempfile, zip_collections[c_name], f, user)
          status = status and retval_status
          #status = status and save_file_to_document(basename, tempfile, zip_collections[c_name], f, user)
        end
      end
    end
    
    #put all parentless zip collections under the user_c
    zip_collections.keys.each do |k|
      c = zip_collections[k]
      if c.parent == nil
        c.parent = user_c

        status = (c.save and status)
      end
    end

    return status
  end
#-----------------------------------------------------------------------
   
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
    
    @opened_file = File.open(file, "r:iso-8859-1")
    stime = Time.now()
    
    #Save Document
    @document=Document.new
    @document.name=fname
    @document.collection=c
    @document.stuffing_text = []
    
    if (File.extname(fname) == ".xlsx")
      @opened_file = Roo::Excelx.new(file, csv_options: {encoding: Encoding::ISO_8859_1})
      
      @opened_file.each_with_pagename do |name, page|
        @document.stuffing_text << page.to_csv
      end
    elsif (File.extname(fname) == ".xls")
      @opened_file = Roo::Excel.new(file, csv_options: {encoding: Encoding::ISO_8859_1})
      
      @opened_file.each_with_pagename do |name, page|
        @document.stuffing_text << page.to_csv
      end
    else
      @opened_file = File.open(file, "r:iso-8859-1")
      file_text = @opened_file.read()
      #Make sure we have valid UTF-8 encoding
      file_text = file_text.encode('UTF-8', :invalid => :replace, :undef => :replace)

      @opened_file.close
      @document.stuffing_text = file_text
    end
=begin
    #File magic incorrectly detects ".xlsx"
    #fm = FileMagic.new  #Checks for excel formats?
    if (\
      (file.kind_of? String) \
      && \
        (\
        (fm.file(file).include?("Excel")) \
        || (fm.file(file).include?("Composite Document"))\
        )\
      )

      @document.stuffing_text = []
      
      #There's a lot of ways to get all the sheets, but this
      # way so far is the quickest
      #@opened_file.workbook.worksheets.each do |worksheet|
      #  @document.stuffing_text << worksheet
      #end
    else
      @opened_file = File.open(file, "r:iso-8859-1")
      file_text = @opened_file.read()
      #Make sure we have valid UTF-8 encoding
      file_text = file_text.encode('UTF-8', :invalid => :replace, :undef => :replace)

      @opened_file.close

      @document.stuffing_text = file_text
    end
=end
    @document.user = user
    document_id = nil

    begin
      status = @document.save
      document_id = @document.id
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
    rescue RestClient::InternalServerError
      log_and_print "ERROR: some other saving problem happend with document #{fname}."
      return false
    end

    return status, document_id
  end
  

  #Adds fields as an array of values in couchDB so they can be searched.
  def get_data_colnames(d)
    if d == nil or d.empty?
      return []
    end
    return d.first().keys()
  end
#-----------------------------------------------------------------------
  #Filter metadata
  #iterator is a string
  def filter_metadata_columns(f, iterator)
    if iterator.class == String
      #spilt the iterator text by endlines
      iterator = iterator.split(/$/)
    #else if iterator.class == File (or anything else), do nothing
    end

    metadata_columns = []
    if f != nil and iterator != nil
      i = 0

      f.get_ifilter_headers.each do |h|
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
        
        row = IfiltersHelper::get_ifiltered_header(h, row)
        
        #If row is length of two, then we want to make a key => val pair out 
        # of the row. Else, the user has matches an unknown amout of values,
        # and we can only number the keys.
        if row.count == 2  #Only one metadata pair per line?
          metadata_columns << {row[0] => row[1]}
        else
          colnames = IfiltersHelper::get_ifiltered_colnames(row)
          for j in (0..row.count-1)
            metadata_col_hash[ colnames[j] ] = row[j]
            if not metadata_col_hash.empty?
              metadata_columns << metadata_col_hash
            end
          end
        end

        i = i + 1 
      end
    else
      metadata_columns = []
    end

    return metadata_columns
  end
#-----------------------------------------------------------------------
  #Removes headers from input stream (iterator) so it can be CSV parsed.
  def strip_metadata(f, iterator)
    if (f == nil or iterator == nil)
      return false
    end
    
    if iterator.class == String
      #spilt the iterator text by endlines, outputs array
      iterator = iterator.split(/$/)
    #else if iterator.class == File (or anything else), do nothing
    end
    
    if f != nil and iterator != nil
      i = 0

      f.get_ifilter_headers.each do |h|
        #metadata_col_hash = {}
        
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

        if ( f['regex'].include?("csv") )    #if (f['regex'] == "csv")
          iterator = strip_header(h, iterator)
        end
        
        #If row is length of two, then we want to make a key => val pair out 
        # of the row. Else, the user has matches an unknown amout of values,
        # and we can only number the keys.

        i = i + 1 
      end
    else
      #metadata_columns = []
    end
    
    if iterator.is_a? Array
      iterator = iterator.join('') #Converts back into string
    end
    iterator = iterator.lstrip #Removes leading whitespace between header and csv

    return iterator
  end
  
  #Removes single header from input stream (iterator) so it can be CSV parsed.
  def strip_header(h, iterator)
    if (h == nil or iterator == nil)
      return false
    end
    
    #Checks if input stream line = filter pattern, removes line if true.
    if (iterator.first =~ /#{h["val"]}/)
      iterator.delete_at(0)
    end

   return iterator
  end
#-----------------------------------------------------------------------
  def filter_data_columns(f, iterator, options = {})
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

    #Excel
    if (f != nil and f['id'] == -3)
      message, retval = filter_data_columns_excel(iterator, options)
      if (retval == true)
        doc = options[:document]
        #Delete this document, we saved the data in sheet docs
        upload_remove(doc) #Validation finished, delete upload
        doc.destroy
      end

      #We don't want our callee to do anything
      #return true
      return message, retval
    end

    #Header metadata + CSV
    if ( f != nil and f['regex'] == "csv" )
      iterator = strip_metadata(f, iterator)
      return filter_data_columns_csv(iterator)
    end

    #Special cases of filtering (regex is treated like command line)
    if ( f != nil and f['regex'] != nil )
      comm = f['regex'].split(" ") #convert to array (to be like ARGV)
    
      if ( comm.include?("-md") )
        iterator = strip_metadata(f, iterator) #Removes and parses metadata
      end
      
      if ( comm.include?("csv") )
        #returns array [metadata,data], "metadata" may be empty
        result_arr = process_comm(comm, iterator)
        return filter_data_columns_csv(result_arr[1])
      end
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
      #save the original for error reporting
      orig_row = row
      data_col_hash = {}
      
      #apply input filters
      if f != nil
       #if row is a hash (i.e. from a Couchdb doc and not a Tempfile),
       # join it back into an Array
       if row.is_a? Hash
        row = row.map {|k,v| v}
       end
        
       #overwrite row with filtered row
       row = f.get_ifiltered_row(row)
       #overwrite col names with numbered colnames
       
       colnames = IfiltersHelper::get_ifiltered_colnames(row)
      else
        row = [row]
      end 
      
      for j in (0..row.count() - 1)
        data_col_hash[ colnames[j] ] = row[j]
      end

      if data_col_hash.empty?
        log_and_print "WARN: the following document row will be filtered out: #{orig_row.to_s}"
        log_and_print "\n"
      end

      data_columns << data_col_hash  
    end

    #filter out empty data columns
    data_columns.reject! { |item| item.empty? }
    return data_columns
  end
#-----------------------------------------------------------------------
  #Takes text (from couch DB) and parses it into CSV format
  #iterator is a string
  def filter_data_columns_csv(iterator)
    retval = []

    if iterator == nil
      return []
    end

    csv = CSV.parse(iterator, :headers => true, :skip_blanks => true)
    
    headers = csv.headers() 
    #check for duplicate field names
    #dup_head = headers.detect {|e| headers.rindex(e) != headers.index(e)}
    dup_head = headers.detect do |e|
      if (!e.empty?) #For empty (e == "") header fields
        headers.rindex(e) != headers.index(e)
      end
    end
    
    if (headers.empty?)
      message = "#### Error: header filtering failed.\n"
      return [message, nil]
    end
    
    if (dup_head != nil)
      message = "### Error: document may contain duplicate column names.\n"
      message << "# Source: " << dup_head << "\n"
      return [message, nil]
    end
    
    csv.each do |row|
      row_hash = (row.to_hash)
      retval << row_hash
    end

    return [message, retval]
  end
#-----------------------------------------------------------------------

  def filter_data_columns_xml(iterator)
    data_text = iterator

    #the hash of the entire xml tree
    xml_hash = Hash.from_xml(data_text)

    #the return data
    data = []

    if (xml_hash != nil and xml_hash["dataroot"] != nil)
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
#-----------------------------------------------------------------------

  #Takes text from excel and CSV filters it. Creates one document for each sheet.
  def filter_data_columns_excel(iterator, options = {})
    retval = false

    if iterator == nil
      return []
    end

    if !options.include?(:document)
      puts "WARN: filter_data_columns_excel() needs a document in the option param."
      return []
    end

    document = options[:document]
    i = 1
    iterator.each do |sheet|
      message, data = filter_data_columns_csv(sheet)
      primary_keys = get_data_colnames(data) #For search

      if (data != nil and !data.empty?)  #create a document for each sheet
        new_doc = Document.new(:name => "#{document.name}_sheet_#{i.to_s}")
        new_doc.collection = document.collection
        new_doc.user = user
        new_doc.stuffing_data = data  #save data to couch
        new_doc.stuffing_primary_keys = primary_keys
        new_doc.stuffing_metadata = [{"HatchFilter" => "Excel (pre-defined)"}]
        new_doc.validated = true
        new_doc.save
        retval = true  #We parsed a sheet successfully.
      end

      i += 1
    end
    message = "Excel validation finished."

    return [message, retval]
  end
#-----------------------------------------------------------------------
=begin
  #Old version; does not parse dates correctly
  def filter_data_columns_excel_old(iterator, options = {})
    retval = false

    if iterator == nil
      return []
    end

    if !options.include?(:document)
      puts "WARN: filter_data_columns_excel() needs a document in the option param."
      return []
    end

    document = options[:document]

    #The original document save put CSV-ish stuff in stuffing_text, so we just have
    # to format the data.
    i = 0
    iterator.each do |sheet|
      colnames = sheet.first

      hash_rows = []
      for row_i in 1..sheet.count
        row = sheet[row_i]
        hash_row = {}
        begin
          for j in (0..row.count() - 1)
            hash_row[ colnames[j] ] = row[j]
          end

          if !hash_row.empty?
            hash_rows << hash_row
          end
        rescue
          puts "WARN: parsing error while processing a sheet in #{document.name}."
        end
      end #each sheet row
    
      if !hash_rows.empty?
        new_doc = Document.new(:name => "#{document.name}_sheet_#{i.to_s}")
        new_doc.collection = document.collection
        new_doc.user = user
        new_doc.stuffing_data = hash_rows
        new_doc.validated = true
        new_doc.save

        #We parsed a sheet successfully.
        retval = true
      end

      i += 1
    end #each sheet

    return retval
  end
=end
#-----------------------------------------------------------------------

  # Gets index columns from the corresponding .xsd file.
  def get_foreign_keys(doc, f)
    doc_name_prefix = doc.name.split('.').first

    xsd_doc = Document.where(:name => doc_name_prefix + '.xsd').first

    foreign_keys = []

    if xsd_doc
      xml_hash = Hash.from_xml(xsd_doc.stuffing_text)

      #get all the xml elements that may hold foreign keys
      xsd_prop_elements = xml_hash["schema"]["element"].each {|row| row if row["name"] == doc_name_prefix }

      #with all the xml elements, find the foreigh keys
      xsd_prop_elements.each do |prop|
        begin
          foreign_keys = prop["annotation"]["appinfo"]["index"].collect {|prop| prop["index_name"]}
        rescue
          #do nothing
        end
      end
    end

    #if we found foreign keys, get rid of xsd file
    if !foreign_keys.empty?
      xsd_doc.destroy
    end

    foreign_keys
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
  
  #TODO finish?: Determines if collection (in a project) has an editor.
  def collection_has_editor(collection)
    project = collection.projects.first
    
    project.collaborators.each do |user|
      if ( user.user_id == current_user )
      end
    end
  end
  

  #If the collection has any viewable docs or sub-collections
  def collection_is_viewable(collection, user, project=nil)
    if collection == nil
      return false
    end

    if collection.user == user
      return true
    end
    
    #collection_has_editor(collection) #makes collection viewable to editor in data view
    
    #If collection is part of a project
    if project != nil && collection.projects.include?(project)
      return true
    end
  
    return false
  end


  def doc_is_viewable(doc, user)
    if doc == nil
      return false
    end

    #Cache the list of all Documents involved with this user, in case this gets called recursively / a lot
    @document_id_list_cache ||= Document.where(:user_id => user.id).collect {|d| d.id}

    #If the doc belongs to the user (because it is in the user doc cache list)
    if @document_id_list_cache.include?(doc.id)
      return true
    end

    #If document is part of a project
    if doc.collection
      doc.collection.projects.each do |project|
        if (doc.collection.projects.include?(project) && project.users.include?(user))
          return true
        end
      end
    end

    #if the user is a collaborator
    if (user != nil and user.documents != nil and user.documents.include?(doc))
      return true
    end
    
    #If document is part of a public project
    if doc.collection
      doc.collection.projects.each do |project|
        if (doc.collection.projects[0].public == true)
          return true
        end
      end
    end
        
    return false
  end

  
  #Adds document to selected project (see view -> documents -> edit)
  def add_project_doc(project, document)
    document.project_id = project.id
  end
#-----------------------------------------------------------------------

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
              row.each {|k,v| csv << [k + ": " + v] }  #csv << row.values
            end

            #Data headings
            # if there is only one column named "1", its the default column for
            # a unfiltered document. Ignore the column.
            if !(@headings.length == 1 and @headings[0] == "1")
              csv << []  #blank row, seperates metadata and data
              csv << @headings
            end
            
            #Data
            document.stuffing_data.each do |row|
                csv << row.values
            end
        end
      elsif document.stuffing_text != nil
        csv_data = document.stuffing_text
      end

        temp_doc = Tempfile.new(document.name)
        temp_doc.write(csv_data)
        temp_doc.rewind #rewind data for zip reading?
      
      doc_list[key] = temp_doc
    end #end doc_list.each loop
  
    return doc_list
  end

  def zip_doc_list_raw(parent_dirs, zipfile, doc_list_raw)
    if (parent_dirs == nil or zipfile == nil or doc_list_raw == nil)
      return false
    end

    #docs for current dir
    doc_list_raw.each do |doc, val|
      upload = Upload.find(doc.stuffing_upload_id)
      rfile = File.open(upload.upfile.path, 'r')
      
      temp_doc = Tempfile.new(doc.name)  #Temperary file with document data
      temp_doc.write(rfile.read)
      temp_doc.rewind #rewind data for zip reading?
      doc_list_raw[doc] = temp_doc

      #If raw document has metadata, create a metadata txt file.
      if (doc.stuffing_metadata. != nil)
        csv_metadata = []
        csv_metadata = CSV.generate do |csv|
          #Metadata
          doc.stuffing_metadata.each do |row|
            row.each {|k,v| csv << [k + ": " + v] }  #csv << row.values
          end
        end
        
        file_name = doc.name + " [metadata].txt"
        temp_file = Tempfile.new(file_name)
        temp_file.write(csv_metadata)
        temp_file.rewind #rewind data for zip reading?
        
        zipfile.put_next_entry( File.join(parent_dirs | [file_name]) )
        zipfile.print IO.read(temp_file)
      end
    end

    doc_list_raw.each do |doc, temp_doc|
      zipfile.put_next_entry(File.join(parent_dirs | [doc.name]))
      zipfile.print IO.read(temp_doc.path)
      temp_doc.close
    end
    
    return true
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
    doc_list_raw = {}
    #key is a document
    collection.documents.each do |key|
    
      if (key.stuffing_raw_file_url != nil)
        doc_list_raw[key] = nil  #Raw file, ignor for now, handel later.
      else
        doc_list[key] = nil
      end
    end

    collection_name = collection.name
    #if collection name is blank, we need some other name
    if collection_name == ""
      collection_name = "(blank)"
    end

    retval = ( retval and zip_doc_list(parent_dirs << collection_name, zipfile, doc_list) )
    retval2 = ( retval and zip_doc_list_raw(parent_dirs << collection_name, zipfile, doc_list_raw) )
    
    collection.children.each do |sub_collection|
      retval =  ( retval and recursive_collection_zip(parent_dirs | [sub_collection.name], zipfile, 
                                                      sub_collection)
                )
    end

    return retval
  end
end
