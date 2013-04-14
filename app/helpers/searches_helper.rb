module SearchesHelper
  include CouchdbHelper
  require 'net/https'

  #TODO: doesn't know about logger. ?
  def log_and_print(str)
    #logger.info str
    puts str
  end

  def couch_search_count_data_in_document(search, lucky_search = false)
    data = []

    conn_hash = get_http_connection_hash

    conn_str = "/#{get_database_name}/_design/all_data_values/_view/view1"
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

    http = Net::HTTP.new(conn_hash[:host], conn_hash[:port])

    if conn_hash[:https] == true
      http.use_ssl = true
    end

    data = []
    http.start do |http|
      req = Net::HTTP::Get.new(conn_str)

      if conn_hash[:https] == true
        req.basic_auth(conn_hash[:username], conn_hash[:password])
      end

      data = JSON.parse(http.request(req).body)["rows"]
    end

=begin
      #data = Document.first().view("all_data_values", "view1", {:group => true, :key => keys})#["rows"]

=end  
    return data
  end


  def couch_search_row_by_doc_and_data(doc_id, search, lucky_search = false)
    data = []

    doc_id = doc_id.to_i #verify the id is really an int
    conn_hash = get_http_connection_hash

    conn_str = "/#{get_database_name}/_design/row_by_doc_and_data/_view/view1"

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

    http = Net::HTTP.new(conn_hash[:host], conn_hash[:port])

    if conn_hash[:https] == true
      http.use_ssl = true
    end

    data = []
    http.start do |http|
      req = Net::HTTP::Get.new(conn_str)

      if conn_hash[:https] == true
        req.basic_auth(conn_hash[:username], conn_hash[:password])
      end

      data = JSON.parse(http.request(req).body)["rows"]
    end

    return data
  end


  def elastic_search_all_data(search)
    data = []

    conn_hash = get_http_connection_hash
    #override with elasticsearch's port
    conn_hash[:port] = 9200

    conn_str = "/#{get_database_name}/#{get_database_name}/_search?q=#{search}"

    data = get_http_search_result(conn_hash, conn_str)

    return data
  end


  def get_http_search_result(conn_hash, conn_str)
    http = Net::HTTP.new(conn_hash[:host], conn_hash[:port])

    if conn_hash[:https] == true
      http.use_ssl = true
    end

    data = []
    http.start do |http|
      req = Net::HTTP::Get.new(conn_str)

      if conn_hash[:https] == true
        req.basic_auth(conn_hash[:username], conn_hash[:password])
      end

      hits = JSON.parse(http.request(req).body)["hits"]["hits"]
      data = hits.collect {|row| {:doc_name => row["_source"]["_id"], :score => row["_score"]} }
    end

    return data
  end

end
