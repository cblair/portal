module DocumentsHelper
  require 'csv'
  require 'zip/zipfilesystem'
  require 'open-uri'
  require 'json'
  require 'cgi'
  require 'filemagic'
  include IfiltersHelper
  include CouchdbHelper

  #helpers for testing devise
  #if Rails.env.test?
  #  include Devise::TestHelpers
  #end

  #Takes metadata from document metadata editor and saves to couch.
  def metadata_save(md_table, document)
    if (md_table == nil or document == nil)
      return false
    end
    #Due to the way the table to json jQuery plugin forms the json string
    # all keys are numbers, this is to make things more readable.
    labelKey = "0"  #Actual key from doc MD table
    valKey = "1"    #Actual value from doc MD table
    doc_md_new = [] #Array of hashes, stores extracted metadata
    
    md_table.each do |key, value|
      md_row = {value[labelKey] => value[valKey]} #Must be "hashified" to save
      doc_md_new << md_row
    end
    document.stuffing_metadata = doc_md_new
    document.save
    
    return true
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
    #logger.info str
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
          status = status and save_file_to_document(basename, tempfile, zip_collections[c_name], f, user)
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
    
    #@opened_file = File.open file
    @opened_file = File.open(file, "r:iso-8859-1")
    stime = Time.now()
    
    #Save Document
    @document=Document.new
    @document.name=fname
    @document.collection=c

    fm = FileMagic.new
    if (\
      (file.kind_of? String) \
      && \
        (\
        (fm.file(file).include?("Excel")) \
        || (fm.file(file).include?("Composite Document"))\
        )\
      )
      @document.stuffing_text = []
      @opened_file = Roo::Excel.new(file, nil, :ignore)
      #There's a lot of ways to get all the sheets, but this
      # way so far is the quickest
      @opened_file.workbook.worksheets.each do |worksheet|
        @document.stuffing_text << worksheet
      end
    else
      #@opened_file = File.open file
      @opened_file = File.open(file, "r:iso-8859-1")
      file_text = @opened_file.read()
      #Make sure we have valid UTF-8 encoding
      file_text = file_text.encode('UTF-8', :invalid => :replace, :undef => :replace)

      @opened_file.close

      @document.stuffing_text = file_text
    end

    #@document.project=p		#links document to project
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
    rescue RestClient::InternalServerError
      log_and_print "ERROR: some other saving problem happend with document #{fname}."
      return false
    end

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
        if row.count == 2
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
  
  #Removes headers from input stream (iteratror) so it can be CSV parsed.
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

        if (f['regex'] == "csv")
          iterator = strip_header(h, iterator)
        end
        
        #If row is length of two, then we want to make a key => val pair out 
        # of the row. Else, the user has matches an unknown amout of values,
        # and we can only number the keys.
=begin
        if row.count == 2
          #metadata_columns << {row[0] => row[1]}
        else
          #colnames = IfiltersHelper::get_ifiltered_colnames(row)
          for j in (0..row.count-1)
            #metadata_col_hash[ colnames[j] ] = row[j]
            if not metadata_col_hash.empty?
              #metadata_columns << metadata_col_hash
            end
          end
        end
=end
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
  
  #Removes single header from input stream (iteratror) so it can be CSV parsed.
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

    #Header metadata + CSV
    if (f != nil and f['regex'] == "csv")
      iterator = strip_metadata(f, iterator)
      return filter_data_columns_csv(iterator)
    end
    
    #Excel
    if (f != nil and f['id'] == -3)
      if filter_data_columns_excel(iterator, options)
        doc = options[:document]
        #Delete this document, we saved the data in sheet docs
        doc.destroy
      end

      #We don't want our callee to do anything
      return true
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

  def filter_data_columns_csv(iterator)
    retval = []

    if iterator == nil
      return []
    end
=begin
    #rows = CSV.parse(iterator)
    rows = CSV.parse(iterator, :skip_blanks => true)

    colnames = rows.first

    (1..rows.length - 1).each do |i|
      row = Hash[[colnames, rows[i]].transpose]
      retval << row
    end
=end
    csv = CSV.parse(iterator, :headers => true, :skip_blanks => true)
    csv.each do |row|
      row_hash = (row.to_hash)
      retval << row_hash
    end

    return retval
  end


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
  

  #If the collection has any viewable docs or sub-collections
  def collection_is_viewable(collection, user, project=nil)
    if collection == nil
      return false
    end

    if collection.user == user
      return true
    end
    
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
      elsif document.stuffing_text != nil
        csv_data = document.stuffing_text
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
    
    collection.children.each do |sub_collection|
      retval =  ( retval and recursive_collection_zip(parent_dirs | [sub_collection.name], zipfile, 
                                                      sub_collection)
                )
    end

    return retval
  end
end
