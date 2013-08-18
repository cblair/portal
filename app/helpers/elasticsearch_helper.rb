module ElasticsearchHelper

  #Facet Searches ------------------------------------------------------
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
  
  #Takes a starting and ending value plus a field, returns a range facet
  #NOTE: it is unclear how this is working
  def es_range_facet(qfrom, qto, sfield)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {
    \"query\" : {
      \"range\" : {
        \"#{sfield}\" : { \"from\" : #{qfrom}, \"to\" : #{qto} }
       }
     },
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
  
  #Takes a staring and ending date plus a date field, returns a date range facet
  def es_date_range_facet(qfrom, qto, sfield)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {
     \"query\" : {
       \"range\" : {
         \"#{sfield}\" : { \"from\" : #{qfrom}, \"to\" : #{qto} }
        }
      },
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
  
  #Takes an interval (e.g. "day", "month") plus a date field,
  #returns a date range histogram
  #TODO: input needs date range?
  def es_date_histogram_facet(sfield, myinterval, qfrom, qto)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {
     \"query\" : {
       \"range\" : {
         \"#{sfield}\" : { \"from\" : \"#{qfrom}\", \"to\" : \"#{qto}\" }
        }
      },
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
  
  #Basic Searches ------------------------------------------------------
  #Match: accept text/numerics/dates, analyzes it, and constructs a query
  #Input: query string, field
  def es_match_search(qstr, sfield)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {
     \"query\" : {
       \"match\" : { \"#{sfield}\" : \"#{qstr}\" }
       }
    }'"

    data = []
    data = es_connect(conn_str, qbody)

    return data
  end
  
  #TODO?: multi match; match multiple fields?
  
  #Filtered: applies a filter to the results of another query
  #Input: query, search field, range field, staring and ending value
  def es_filtered_search(qstr, sfield, rfield, qfrom, qto)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {
     \"query\" : {
       \"filtered\" : {
         \"query\" : { \"term\" : { \"#{sfield}\" : \"#{qstr}\" } },
         \"filter\" : {
            \"range\" : {
              \"#{rfield}\" : { \"from\" : \"#{qfrom}\", \"to\" : \"#{qto}\" }
            }
          }
        }
      }
    }'"

    data = []
    data = es_connect(conn_str, qbody)

    return data
  end
  
  #Fuzzy Like This: find documents that are “like” provided text by
  # running it against a single field
  #Input: text, field name, max query terms
  def es_flt_field_search(qtext, sfield, max)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {
     \"query\" : {
       \"fuzzy_like_this_field\" : {
         \"#{sfield}\" : {
            \"like_text\" : \"#{qtext}\",
            \"max_query_terms\" : #{max}
          }
        }
      }
    }'"

    data = []
    data = es_connect(conn_str, qbody)

    return data
  end
  
  #TODO?: More like this field?
  
  #Prefix Query: Matches documents that have fields containing terms
  # with a specified prefix (not analyzed)
  #Input: query and field strings
  def es_prefix_search(qstr, sfield)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {
     \"query\" : {
       \"prefix\" : { \"#{sfield}\" : \"#{qstr}\" }
      }
    }'"

    data = []
    data = es_connect(conn_str, qbody)

    return data
  end
  
  #Query String: uses a query parser in order to parse its content
  #Input: query string
  def es_query_string_search(qstr)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {
     \"query\" : {
       \"query_string\" : {
         \"query\" : \"#{qstr}\"
        }
      }
    }'"
    
    data = []
    data = es_connect(conn_str, qbody)
    
    return data
  end
  
  #Range: Matches documents with fields that have terms within a certain range
  #Input: field string, starting and ending value
  def es_range_search(sfield, qfrom, qto)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {
     \"query\" : {
       \"range\" : {
         \"#{sfield}\" : { \"from\" : #{qfrom}, \"to\" : #{qto} }
        }
      }
    }'"
    
    data = []
    data = es_connect(conn_str, qbody)
    
    return data
  end
  
  #TODO?: Span searches?
  
  #Term: Matches documents that have fields that contain a term (not analyzed)
  #Input: query and field string (query -> lower case, field -> uppercase?)
  def es_term_search(qstr, sfield)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {
     \"query\" : {
       \"term\" : { \"#{sfield}\" : \"#{qstr}\" }
      }
    }'"
    
    data = []
    data = es_connect(conn_str, qbody)
    
    return data
  end
  
  #TODO: terms search (non facet?)
  
  #Wildcard: Matches documents that have fields matching a wildcard
  # expression (not analyzed)
  #Input: query and field string (query -> lower case, field -> uppercase?)
  def es_wildcard_search(qstr, sfield)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {
     \"query\" : {
       \"wildcard\" : { \"#{sfield}\" : \"#{qstr}\" }
      }
    }'"
    
    data = []
    data = es_connect(conn_str, qbody)
    
    return data
  end
  
  #SAS for testing and debuging ONLY!
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

    full_data = get_es_http_search_result2(conn_hash, conn_str, qbody)
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
  def get_es_http_search_result2(conn_hash, conn_str, qbody)
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
