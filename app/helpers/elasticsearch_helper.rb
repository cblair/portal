module ElasticsearchHelper

  #Takes a query and field string, returns terms facet information
  def es_terms_facet(qstr, sfield)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {\"query\": 
      {\"query_string\": {\"query\":\"#{qstr}\"} },
       \"facets\": 
         {\"#{sfield}\": 
              {\"terms\": 
                {\"field\" : \"#{sfield}\"}
              }
         }
    }'"
    
    data = []
    data = es_connect(conn_str, qbody)
    
    return data
  end
  
  def es_range_facet(qfrom, qto, sfield)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {\"query\" : {\"match_all\" : {} },
       \"facets\" : {
         \"myrange\" : {
           \"range\" : {
             \"field\" : \"#{sfield}\",
               \"ranges\" : [
                 { \"from\" : \"#{qfrom}\", \"to\" : \"#{qto}\" }
                 ]
              }
            }
          }
    }'"
    
    data = []
    data = es_connect(conn_str, qbody)

    return data
  end
  
  #Date range none histogram
  def es_date_range_facet(qfrom, qto, sfield)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {\"query\" : {\"match_all\" : {} },
       \"facets\" : {
         \"dates\" : {
           \"range\" : {
             \"field\" : \"#{sfield}\",
               \"ranges\" : [
                 { \"from\" : \"#{qfrom}\", \"to\" : \"#{qto}\" }
                 ]
              }
            }
          }
    }'"
    
    data = []
    data = es_connect(conn_str, qbody)

    return data
  end
  
  #Date range histogram
  def es_date_histogram_facet(sfield, myinterval)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    #conn_str = "curl -XGET http://localhost:9200/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {\"query\" : { \"match_all\" : {} },
       \"facets\" : {
         \"dates\" : {
           \"date_histogram\" : {
             \"field\" : \"#{sfield}\",
             \"interval\" : \"#{myinterval}\"
            }
          }
        }
    }'"
        
    data = []
    data = es_connect(conn_str, qbody)

    return data
  end
  
  #SAS format testing
  def es_test(qstr, sfield)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "{\"query\":{\"match\":{\"#{sfield}\":\"#{qstr}\"}}}'"
    
    data = []
    data = es_connect(conn_str, qbody)
    
    return data
  end

  #Basic URL search, for testing
  def elastic_search_url(search)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?q=#{search}"
    #data = []
    data = es_connect(conn_str, qbody)
    
    return data
  end

  #Takes ES connection string, calls http, performs some post processing,
  # returns raw queried data
  def es_connect(conn_str, qbody)
    conn_hash = get_http_connection_hash
    #override with elasticsearch's port
    conn_hash[:port] = 9200
    
    puts "Elasticsearch query: #{conn_str} #{qbody}, with connection:"
    puts conn_hash.inspect

    full_data = get_es_http_search_result(conn_hash, conn_str, qbody)
    data = []

    begin
      hits = full_data["hits"]["hits"]
      data = hits.collect {|row| {:doc_name => row["_source"]["_id"], :score => row["_score"]} }
    rescue NoMethodError
      log_and_print "WARN: elastic_search_all_data missing data in reponse. Full response:"
      log_and_print full_data.to_s
    end

    return data
  end
  
  #SAS new version, needed for more advanced ES queries
  def get_es_http_search_result(conn_hash, conn_str, qbody)
    http = Net::HTTP.new(conn_hash[:host], conn_hash[:port])

    if conn_hash[:https] == true
      http.use_ssl = true
    end

    data = []
    http.start do |http|
      uri = URI.encode(conn_str) #Encodes URL part into uri obj
      
      req = Net::HTTP::Get.new(uri)
      req.body = qbody #Appends JSON query to uri, should be seperate from connection string

      if conn_hash[:https] == true
        req.basic_auth(conn_hash[:username], conn_hash[:password])
      end
      
      response_data = http.request(req)
      data = JSON.parse(response_data.body)
      
      puts data
    end

    return data
  end

end
