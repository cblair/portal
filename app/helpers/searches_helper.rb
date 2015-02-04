#TODO: this file nees much refactoring; most methods to be
# called through the dispatcher, and the redundant portion taken out

module SearchesHelper
  include CouchdbHelper
  require 'net/https'

  #TODO: doesn't know about logger. ?
  def log_and_print(str)
    #logger.info str
    puts str
  end
  
  #Gets info about doc for search popup including:
  #1. List of projects this document is in.
  #2. List of parent collections (path)
  def get_doc_info_search(document)
    if (document == nil)
      return false
    end

    doc_info_pop = '<p>Name: ' << document.name << '</p>'
    collection = Collection.find(document.collection)
    
    doc_info_pop << '<p>Collections: '
    collection.path.each do |col|
      doc_info_pop << link_to(col.name, col) << " >"
    end
    doc_info_pop << '</p>'
    
    doc_info_pop << '<p>Projects: '
    collection.projects.each do |project|
      doc_info_pop << link_to(project.name, project) << " |"
    end
    doc_info_pop << '</p> <hr>'
    
    doc_info_pop << '<p>Created: ' << document.created_at.to_s << '</p>'
    doc_info_pop << '<p>Modified: ' << document.updated_at.to_s << '</p>'

    return doc_info_pop
  end

  def couch_dispatcher(design_doc_name, view_name, options = {})
    data = []

    conn_hash = get_http_connection_hash

    conn_str = "/#{get_database_name}/_design/#{design_doc_name}/_view/#{view_name}"
    
    @options = options
    conn_str += send(design_doc_name)

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

      data = JSON.parse(http.request(req).body)
    end

    puts data 
    return data["rows"]
  end

  def all_data_keys
    search = @options[:search]
    limit = @options[:limit] || 10

    params = "?group=true"
    params += "&limit=#{limit}"

    #Start key starts with whatever the 
    startkey = '"' + CGI.escape("#{search}") + '"'
    #Get the last possible key with this prefix ('z'). It would be better to
    # set this to the end of the UTF values (or even ASCII), but the latest
    # working char is 'z'.
    endkey =   '"' + CGI.escape("#{search}z") + '"'

    params += "&startkey=" + startkey
    params += "&endkey=" + endkey

    params
  end

  #############################################################################
  ## The following need refactoring to use couch_dispatcher().
  #############################################################################

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
      elsif mode == "doc_list"
        data = hits["hits"]["hits"]
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
    retval = {:viewable_docs => [], :unviewable_docs => []}

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
          retval[:unviewable_docs] << doc
        end
      end
    end
    
    retval
  end
  
#-----------------------------------------------------------------------
  #Gets only document ids from ES (fast).
  def search_ids_es()
    puts "search_ids help**********************************************"

    search = ""
    doc_results = []
    viewable_doc_list = []
    unviewable_doc_list = []
    colnames = []
    result_rows = []

    if params.include?("searchIDs")
      search = params["searchIDs"]
    end

    if search != ""
      page_new = ( params["page"].to_i )
      page_new = (page_new <= 0? 0 : page_new - 1) #page 0 and 1 are the same
      page_curr = page_new * per_page
      
      options =  {
                  :flag => 'ids', #ids only, get total hits
                  :get_full_data => false, #dont return full documents
                  :from => page_curr ||= page,
                  :size => per_page
                }

      start_time = Time.new
      results, total = ElasticsearchHelper::es_search_dispatcher("es_query_string_search", search, options)
      run_time_seconds = Time.new - start_time
      puts "INFO: Elasticsearch query completed in #{run_time_seconds.inspect} seconds."
      puts "results2 ***************************************************"
      p results
      
      doc_results = get_viewable_and_nonviewable_docs_from_raw_es_data(results, current_user)
      viewable_doc_list = doc_results[:viewable_docs]
      unviewable_doc_list = doc_results[:unviewable_docs]

      #Don't let unvalidated docs screw up the search results
      validated_doc_list = viewable_doc_list.reject {|doc| !doc.validated }
      if !validated_doc_list.empty?
        colnames = get_colnames_in_common(validated_doc_list)
      end
    end # if search != ""
=begin
    #Setup colnames for merge search if results have colnames in common.
    colnames_in_common_and_merge_search = (!colnames.empty?) && (merge_search)
    if !colnames_in_common_and_merge_search
      #colnames = ["Documents", "Metadata", "Information"]
      colnames = ["Documents", "Information"]
    end

    unviewable_doc_links = unviewable_doc_list[0..10].collect do |doc|
      if doc.user
        view_context.mail_to doc.user.email, "#{doc.name} - request access via email.", subject: "Requesting access to #{doc.name}"
      end
    end
    unviewable_doc_links.reject! {|l| !l}
=end
    search_data = {
      "documents" => viewable_doc_list,
      "colnames" => ["Documents", "Metadata", "Information"],
      "doc_links" => [],
      #Show some unviewable doc links, but only the first 10 in case there's a lot.
      "unviewable_doc_links" => []
    }

    return search_data, total
  end
#-----------------------------------------------------------------------
end
