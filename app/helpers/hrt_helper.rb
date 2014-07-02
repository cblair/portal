#Hatch Reformat Tool: Library Code
module HrtHelper
  $add_quotes = false
  $csv_hash = false
  
  #HRT helper functions
  ########################################################################
  
  #Converts a file obj to a string (to be like Hatch)
  def convert_to_string(ins)
    string = ""
    #puts "convert_to_string..."
    ins.each do |line|
      string << line
      #p line
    end
    return string
  end
  #-----------------------------------------------------------------------
  
  #Displays contents of document after CSV parsing
  def show_doc(retval_arr)
    message = retval_arr[0]
    table = retval_arr[1]
    
    table.each do |row|
      puts row
    end
    puts
  end
  #-----------------------------------------------------------------------
  
  #Displays contents of CSV obj
  def show_csv(csv)
    csv.each do |row|
      p row
    end
    puts
  end
  
  ########################################################################
  #Error detection, after parsing, detects possible temperature errors
  #NOTE: Not being used (in Hatch)
  def detect_err(csv_doc)
    temp_min = 0
    temp_max = 100
  
    puts "### Error detection."
    
    csv_doc.each do |row|
      temp = row[2].to_f
      if (temp < temp_min)
        puts "### Error: temperature to low?", temp
      end
      if (temp > temp_max)
        puts "### Error: temperature to high?", temp
      end
    end
  end
  
  #Cuts out metadata
  def md_slice(iterator, skip_lines)
    metadata = ""
    
    for i in (0..skip_lines-1)
      metadata << iterator.lines[i] #gets n lines of metadata to cut
    end
    iterator.slice!(metadata) #cuts out metadata
    
    #p "md_slice", metadata
    #p "md_slice", iterator
    
    return metadata
  end
  #-----------------------------------------------------------------------
  
  #Removes and returns a line (string) of an input "document" (string)"
  def cut_line(iterator)
    line = iterator.lines.first
    
    row = iterator.slice(line)
    iterator.slice!(line)
    
    return row
  end
  
  #Takes 2 parsed CSV headers (arrays) and merges them into one string
  #Adds an optional seperator and/or unit container
  def merge_headers(head1, head2, sepr="", open="", close="")
    merged_arr = head1.zip(head2) #merges 2 headers (arrays) together into a "2D" array
  
    merged_str = []
    #converts merged array into a string (with optional seperator and opening/closeing containers)
    merged_arr.each do |h1,h2|
      if (h1.empty? and h2.empty?)
        h3 = '""' #empty double header cells should stay empty
      else
        h3 = h1 + sepr + open + h2 + close
      end
      merged_str << h3
    end
    return merged_str
  end
  #-----------------------------------------------------------------------
  
  #Replaces instances of nil in an array with an empty (blank) string ""
  def nil_blank(array)
    if ( array.include?(nil) ) #replace nil with empty string
      array.map! {|e| e ? e : ""}
    end
    return array
  end
  #-----------------------------------------------------------------------
  
  #Merges a double header into a single header
  def double_header(iterator)
    #p "double_header iterator", iterator
    head1 = cut_line(iterator)  
    #p "head1", head1
    head1_csv = CSV.parse(head1).flatten  
    #p "head1_csv", head1_csv
    head1_csv = nil_blank(head1_csv)  
    #p "head1_csv", head1_csv
    head1_csv.collect!{|str| str.strip} #leading and trailing whitespace removed
    #p "head1_csv", head1_csv  
    #puts ""
  
    head2 = cut_line(iterator)  
    #p "head2", head2
    head2_csv = CSV.parse(head2).flatten  
    #p "head2_csv", head2_csv
    head2_csv = nil_blank(head2_csv)  
    #p "head2_csv", head2_csv
    head2_csv.collect!{|str| str.strip} #leading and trailing whitespace removed
    #p "head2_csv", head2_csv
    
    merged_arr = merge_headers(head1_csv, head2_csv, " ", "[", "]")
    
    #Adds quotes around fields (helps avoid CSV parse bugs)
    if ($add_quotes == true)
      merged_arr.map! {|s| "\"#{s}\"" }
    end
    
    new_head = merged_arr.join(',')  #creats string with "," as sperator
    new_head << "\r\n"  #So CSV can parse headers
    new_iterator = new_head << iterator #combines new header with data
    return new_iterator
  end
  #-----------------------------------------------------------------------
  
  #Type 1; Custom filter for Sonde data like the following
  #"========","========"
  #"    Date","    Time"
  #"   m/d/y","hh:mm:ss"
  #"--------","--------"
  def sonde_data_filter(iterator)
    cut_line(iterator)
    head1 = cut_line(iterator)
    head1_csv = CSV.parse(head1).flatten
    head1_csv.collect!{|str| str.strip}
    
    head2 = cut_line(iterator)
    head2_csv = CSV.parse(head2).flatten
    head2_csv.collect!{|str| str.strip}
    cut_line(iterator)
    
    merged_str = merge_headers(head1_csv, head2_csv, " ", "[", "]")
    
    new_head = merged_str.join(',')
    new_head << "\r\n"
    new_iterator = new_head << iterator
    #puts new_iterator
    return new_iterator
  end
  
  ########################################################################
  
  #Command line flag processing.
  def process_comm(comm, doc)

    #Adds quotes to header
    if ( comm.include?("-q") )
      $add_quotes = true
    end
  
    #Ignore (skip) "x" number of lines (may include metadata)
    metadata = ""
    if ( comm.include?("-s") )
      skip_index = comm.index("-s") + 1
      skip_lines = comm[skip_index].to_i
      metadata = md_slice(doc, skip_lines) #Remove metadata
      #cut_line(doc) #remove line between metadata and header
    end
  
    #Parse double header flag
    if ( comm.include?("-d") )
      doc = double_header(doc) #Merge two row headers
    end
  
    #Parse special formats by "types"
    if ( comm.include?("-t") )
      type_index = comm.index("-t") + 1
      type = comm[type_index].to_i
    
      if (type == 1)
        doc = sonde_data_filter(doc) #Custom header reformat
      end
    end
  
    #Use CSV parsing to convert input string into hash
    #if ( comm.include?("-csvh") )
      #$csv_hash = true
    #end
  
    return [metadata, doc]
  end

end
