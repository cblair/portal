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

    if data == nil
      data = []
    end

    return data
  end

  #
  # doc_id - The document ID.
  # limit - how many rows to return.
  # skip - how many rows to skip.
  def couchdb_view__all_rows(doc_id, limit, skip)
    data = []

    doc_id = doc_id.to_i #verify the id is really an int
    limit = limit.to_s
    skip = skip.to_s

    conn_hash = get_http_connection_hash

    conn_str = "/#{get_database_name}/_design/all_rows/_view/view1"

    startkey = "\"Document-#{doc_id.to_s}\""
    endkey = "\"Document-#{doc_id.to_s}\""

    conn_str += "?startkey=" + CGI.escape(startkey)
    conn_str += "&endkey=" + CGI.escape(endkey)

    conn_str += "&limit=" + CGI.escape(limit)
    conn_str += "&skip=" + CGI.escape(skip)

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

    if data == nil
      data = []
    end

    return data
  end


  def couchdb_view__all_row_count(doc_id)
    data = []

    doc_id = doc_id.to_i #verify the id is really an int
    limit = limit.to_s
    skip = skip.to_s

    conn_hash = get_http_connection_hash

    conn_str = "/#{get_database_name}/_design/all_row_count/_view/view1"

    startkey = "\"Document-#{doc_id.to_s}\""
    endkey = "\"Document-#{doc_id.to_s}\""

    conn_str += "?startkey=" + CGI.escape(startkey)
    conn_str += "&endkey=" + CGI.escape(endkey)

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

    if data == nil
      data = []
    end

    return data
  end


  def elastic_search_all_data(search, mode="doc_names")
    data = []

    conn_hash = get_http_connection_hash
    #override with elasticsearch's port
    conn_hash[:port] = 9200

    conn_str = "/#{get_database_name}/#{get_database_name}/_search?q='#{search}'"

    puts "Elasticsearch query: #{conn_str}, with connection:"
    puts conn_hash.inspect

    full_data = get_http_search_result(conn_hash, conn_str)
    data = []

    hits = nil
    begin
      hits = full_data
    rescue NoMethodError
      log_and_print "WARN: elastic_search_all_data missing data in reponse. Full response:"
      log_and_print full_data.to_s
    end

    if hits
      data = hits["hits"]["hits"]
      if mode == "doc_names"
        data = data.collect {|row| {:doc_name => row["_source"]["_id"], :score => row["_score"]} }
      end
    end

    return data
  end

   #This is Lucene for the Hatch production on Heroku, via the Cloudant API
   def cloudant_search_all_data(search)
    data = []

    conn_hash = get_http_connection_hash
    #conn_str = "/#{get_database_name}/_design/all_data_values/_search/cols_and_values?q=#{search}"

    #TODO - overwriting with our production stuff only
    conn_hash[:host] = "app10534904.heroku.cloudant.com"
    conn_hash[:https] = true
    conn_hash[:port] = 443
    conn_hash[:username] = "app10534904.heroku"
    conn_hash[:password] = "QTRGjtDrQkATkjPuCGUAVUPh"
    conn_str = "/app_production/_design/all_data_values/_search/cols_and_values?q=#{search}"

    data = get_http_search_result(conn_hash, conn_str)

    return data["rows"]
  end

  def elastic_search_all_and_return_doc_ids(search, current_user)
    raw_data = elastic_search_all_data(search)

    retval = []

    raw_data.collect do |row|
      doc_name = row[:doc_name]
      score = row[:score]
      doc_id = doc_name.sub("Document-", "").to_i

      begin
        doc = Document.find(doc_id)
      rescue ActiveRecord::RecordNotFound
        log_and_print "WARN: Document #{doc_name} with id #{doc_id} not found in search. Skipping. Raw search return data:"
        puts raw_data

        next
      end

      if doc == nil
        log_and_print "WARN: Document #{doc_name} with id #{doc_id} not found"
      elsif doc_is_viewable(doc, current_user)
        retval << doc.id
      end
    end

    retval
  end

  #SAS Old version, will not parse more advanced ES queries.
  #See "elasticsearch_helper" for newer version.
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
      temp = http.request(req).body
      
      data = JSON.parse(http.request(req).body)
    end

    return data
  end


  def get_colnames_in_common(doc_list)
    #Colnames is all the column names they have in common
    colnames = get_data_colnames(doc_list[0].stuffing_data)

    doc_list.each do |doc| 
      colnames = get_data_colnames(doc.stuffing_data) & colnames
    end

    colnames
  end

  #Gets only the viewabled docs
  def get_docs_from_raw_es_data(raw_data, current_user)
    return get_viewable_and_nonviewable_docs_from_raw_es_data(raw_data, current_user)[:viewable_docs]
  end

  #Gets all docs
  def get_viewable_and_nonviewable_docs_from_raw_es_data(raw_data, current_user)
    retval = {:viewable_docs => [], :nonviewable_docs => []}

    if raw_data
      raw_data.collect do |row|
        doc_name = row["_id"]
        doc_id = doc_name.sub("Document-", "").to_i

        begin
          doc = Document.find(doc_id)
        rescue ActiveRecord::RecordNotFound
          log_and_print "WARN: Document #{doc_name} with id #{doc_id} not found in search. Skipping."

          next
        end

        if doc == nil
          log_and_print "WARN: Document #{doc_name} with id #{doc_id} not found"
        elsif doc_is_viewable(doc, current_user)
          retval[:viewable_docs] << doc
        else
          retval[:nonviewable_docs] << doc
        end
      end
    end
    
    retval
  end

end
