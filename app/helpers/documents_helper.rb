module DocumentsHelper
  
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
  
  #Gives the count of every value in a column
  def get_data_map(d, colname)
    data_columns = []
    dc=get_data_column(d,colname)
    dc = dc.group_by(&:capitalize).map {|k,v| {k => v.length}}
    
    dc.each do |row|
      data_col_hash = {}
      colnames = ["value","map"]
      key = row.keys().first()
      data_col_hash["value"] = key
      data_col_hash["map"] = row[key]
      data_columns << data_col_hash
    end

    return data_columns
  end
  
  def document_search_data_couch(search)
    #Save the search string to each document so views can look it up
    Document.all().each do |doc|
      doc.stuffing_search = search
      doc.save
    end
    
    #Use any Document instance to access the Stuffing view method
    retval = []
    docs = Document.first().view()["rows"]
    docs.each do |doc|
      retval << doc["value"]
    end
    
    return retval
  end
end
