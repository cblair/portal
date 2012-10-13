module DocumentsHelper
  require 'csv'
  require 'zip/zipfilesystem'
  include IfiltersHelper
  
  # @param zip_fname A string of the zip file name
  # @param zip_file_object A file object for the zip file
  # @param user_c A Collection object
  # @param f A IFilter object
  def save_zip_to_documents(zip_fname, zip_file_object, user_c, f)
    #TODO: replace all back slagshes with forward slashes
    
    #a dictionary of dircetories, than point to collections 
    zip_collections = {}
          
    Zip::ZipFile.open(zip_file_object.tempfile) do |zipfile|
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
          c.save
          
          #save to collections dictionary
          zip_collections[fname] = c
        else
          tempfile = Tempfile.new(basename)
          tempfile.binmode
          tempfile.write file.get_input_stream.read
          tempfile.rewind
          tempfile.close
          
          c_name = File.dirname(fname)
          save_file_to_document(fname, tempfile, zip_collections[c_name], f)
        end
      end
    end
    
    #put all parentless zip collections under the user_c
    zip_collections.keys.each do |k|
      c = zip_collections[k]
      if c.collection == nil
        c.collection = user_c
        c.save
      end
    end
  end
   
   
  #save a file from a web upload to an db doc
  # 
  # @param fname A string of the file name
  # @param c A Collection object
  # @param f A IFilter object
  def save_file_to_document(fname, file, c, f)
    #csv import. Each call on @parsed_file.<method> increments the cursor
    begin
      if CSV.const_defined? :Reader
          @parsed_file=CSV::Reader.parse(fname)
      else
          @parsed_file=CSV::CSV.open(file)
      end
    rescue
      return #unsupported file type
    end

    #get the column names
    colnames=[]
    if params[:dump][:contains_header] == "1"
      colnames = @parsed_file.first()
    else
      colnames = [1]
    end
    
    data_columns=[]
    i = 0
    @parsed_file.each do |row|
      data_col_hash = {}
      
      #apply input filter
      if f != nil
       #overwrite row with filtered row
       row = get_filtered_row(f, row)
       #overwrite col names with numbered colnames
       
       colnames = get_filtered_colnames(row)
      end
      
      for j in (0..row.count-1)
        data_col_hash[ colnames[j] ] = row[j]
      end
      
      #data_columns[i] = data_col_hash
      #i = i + 1
      data_columns << data_col_hash  
    end
    
    #Remove empty elements
    data_columns.reject! { |item| item.empty? }
    
    #Transform all values to native ruby types
    data_columns=convert_data_to_native_types(data_columns)
    
    #Save Document
    #TODO: bug, 'create' is not working now, makes all values nill. Going to 'new'. ?
    #d=Document.create(  :name => fname,
    #                    :collection => c,
    #                    :stuffing_data => data_columns
    #                  )
    @document=Document.new
    @document.name=fname
    @document.collection=c
    @document.stuffing_data=data_columns
    @document.save
  end
  
  def get_data_colnames(d)
    if d.empty?
      return []
    end
    return d.first().keys()
  end
  
  #Converts row value strings to native data type if possible
  #TODO: probably needs to be values in record that user can update
  def convert_data_to_native_types(d)
    #TODO: replace with get_data_colnames
    #colnames=d.first().keys()
    colnames = get_data_colnames(d)
    colnames.each do |colname|
      #*binary
      #*boolean

      #*date
      #*datetime
      count = 0
      d.each do |row|
        begin
          DateTime.strptime(row[colname], '%m/%d/%y %H:%M:%S')
          count = count + 1
        rescue
          #do nothing
        end
      end
      #if counts match, convert
      if d.count == count
        #TODO: make more efficient
        d.find_all {|item| item[colname] = DateTime.strptime(item[colname], '%m/%d/%y %H:%M:%S') }
        next #next column
      end
      #*time
      #*timestamp
    
      #*decimal

      #*float

      #*integer
      #Integer
      if d.count == d.find_all {|item| item[colname].match(/^[0-9]+$/)}.count
        d.find_all {|item| item[colname] = Integer(item[colname]) }
        next
      end
    
      #*string - smaller than text
      #*text - default, no change
    end
  
  return d
  end
  

  def get_data_column(d, colname)
    dc = []
    d.stuffing_data.find_all {|item| dc << item[colname]}
    return dc
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
end
