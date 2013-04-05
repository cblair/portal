module SearchesHelper
  include CouchdbHelper

  #TODO: doesn't know about logger. ?
  def log_and_print(str)
    #logger.info str
    puts str
  end

  def couch_search_count_data_in_document(search, lucky_search = false)
    data = []

    conn_str = get_http_connection_string + "#{get_database_name}/"

    conn_str += "_design/all_data_values/_view/view1"

    conn_str += "?group=true"

    conn_str += "&limit=10"

    #Use any Document instance to access the Stuffing view method
    #If exact value searched for, call key view
=begin
    if lucky_search == true
      key = "[#{search}]"

      conn_str += "&key=" + CGI.escape(key)
=end
    #else
      startkey = "[\"#{search}\"]"
      endkey =   "[\"#{search}\ufff0\"]"

      conn_str += "&startkey=" + CGI.escape(startkey)
      conn_str += "&endkey=" + CGI.escape(endkey)
	  #end

    #TODO: might not need this anymore...
    #begin
      data = JSON.parse(open(conn_str).read)['rows']
    #rescue OpenURI::HTTPError
    #  log_and_print "WARN: User did a search with bad URI: "
    #  log_and_print '-->' + conn_str
    #end
=begin
      #data = Document.first().view("all_data_values", "view1", {:group => true, :key => keys})#["rows"]

=end  
    return data
  end


  def couch_search_row_by_doc_and_data(doc_id, search, lucky_search = false)
    data = []

    doc_id = doc_id.to_i #verify the id is really an int
    conn_str = get_http_connection_string + "#{get_database_name}/"

    conn_str += "_design/row_by_doc_and_data/_view/view1"

    #Use any Document instance to access the Stuffing view method
    #If exact value searched for, call key view
=begin
    if lucky_search == true
      key = "[\"Document-#{doc_id.to_s}\",#{search}]"

      conn_str += "?key=" + CGI.escape(key)
    else
=end
      startkey = "[\"Document-#{doc_id.to_s}\",\"#{search}\"]"
      endkey = "[\"Document-#{doc_id.to_s}\",\"#{search}\ufff0\"]"

      conn_str += "?startkey=" + CGI.escape(startkey)
      conn_str += "&endkey=" + CGI.escape(endkey)
    #end

    #TODO: may not need this
    #begin
      puts "TS"
      puts conn_str
      data = JSON.parse(open(conn_str).read)['rows']
    #rescue OpenURI::HTTPError
    #  log_and_print "WARN: User did a search with bad URI: "
    #  log_and_print '-->' + conn_str
    #end

    return data
  end

end
