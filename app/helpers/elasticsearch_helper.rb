module ElasticsearchHelper

  require 'uri'

  #gets set by the actual query receiver, before we parse it out
  @@document_count = 0

  #Extend this helper off of CouchdbHelper
  extend CouchdbHelper
  def self.included(base)
    base.send :extend, CouchdbHelper
  end

  def self.get_document_count
    @@document_count
  end

  #############################################################################
  ##  Internal utility methods
  #############################################################################

  #Basic URL search, for testing
  def self.elastic_search_url(search)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?q=#{search}"
    #data = []
    data = es_connect_md(conn_str, qbody)
    
    return data
  end
=begin
  def self.es_connect_ids(conn_str, qbody, get_full_data = false)
    conn_hash = get_http_connection_hash
    #override with elasticsearch's port
    conn_hash[:port] = 9200
    
    full_data = get_es_http_search_result2(conn_hash, conn_str, qbody)
    data = []
    total = "" #total hits

    begin
      #Get the document count
      @@document_count = full_data["hits"]["total"]
      
      if get_full_data
        data = full_data
      else
        data = full_data["hits"]["hits"]
        total = full_data["hits"]["total"]
      end
    rescue NoMethodError
      puts "WARN: ES query missing data in reponse."
      #Leaving this reporting data out, as its too slow.
      #puts full_data.to_s
    end
    
    return data, total
  end
=end
  #Takes ES connection string, calls http, performs some post processing,
  # returns document metadata, not the full doc.
  def self.es_connect_md(conn_str, qbody, get_full_data = false)
    conn_hash = get_http_connection_hash
    #override with elasticsearch's port
    conn_hash[:port] = 9200
    
    full_data = get_es_http_search_result2(conn_hash, conn_str, qbody)
    data = []
    total = "" #total hits

    begin
      #Get the document count
      @@document_count = full_data["hits"]["total"]
      
      if get_full_data
        data = full_data
      else
        #hits = full_data["hits"]["hits"]  #KEEP
        #data = hits.collect {|row| {:doc_name => row["_id"], :score => row["_score"]} } #KEEP
        data = full_data["hits"]["hits"]
        total = full_data["hits"]["total"]
      end
    rescue NoMethodError
      puts "WARN: ES query missing data in reponse."
      #Leaving this reporting data out, as its too slow.
      #puts full_data.to_s
    end
    
     return data, total
  end

  #Takes ES connection string, calls http, performs some post processing,
  # returns raw queried data, full documents.
  def self.es_connect(conn_str, qbody, get_full_data = false)
    conn_hash = get_http_connection_hash
    #override with elasticsearch's port
    conn_hash[:port] = 9200
    
    puts "Elasticsearch query: #{conn_str} -d '#{qbody}', with connection:"
    puts conn_hash.inspect

    full_data = get_es_http_search_result2(conn_hash, conn_str, qbody)
    begin
      #Get the document count
      @@document_count = full_data["hits"]["total"]

      #Return all the data if wanted, else just the hits.
      if get_full_data
        data = full_data
      else
        data = full_data["hits"]["hits"]
      end
    rescue
      log_and_print "WARN: search had not results."
      #Leaving this reporting data out, as its too slow.
      #log_and_print full_data.inspect
    end

    return data
  end
#-----------------------------------------------------------------------
  #SAS new version, needed for more advanced ES queries
  def self.get_es_http_search_result2(conn_hash, conn_str, qbody)
    #Last formatting needed for multiline JSON.
    conn_str += "-d "
    qbody = "#{qbody}"

    puts "Sending ES request: #{conn_str} #{qbody} with connection:"
    puts conn_hash.inspect

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
      
    end

    return data
  end
  
  #Determines if the search should return document metadata only or the
  # full document
  def self.search_type(flag)
    str = ""
    
    if (flag == "m")
      str = "\"fields\" : []" #ES command for document metadata only
    elsif (flag == "f")
      str = ""
    end
    
    return str
  end

  #############################################################################
  ##  Pre-processing
  ##  These functions process options and flags.
  #############################################################################

  #Usually the first function called (for now).
  #Determines which search type to use. 
  def self.es_search_dispatcher(type, qstr, options)
    #Get required options.
    get_full_data = options[:get_full_data] || false
    flag = options[:flag] || 'm'
    flag_str = search_type(flag)

    #Strip off beginning and end url escape single quotes from the query string,
    # if they exist
    if (qstr[0] == "'") && (qstr[-1] == "'")
      qstr[0] = ""
      qstr[-1] = ""
    end

    #TODO: we need to escape some chars, but URI escape is too much and will fail
    #qstr = URI.escape(qstr)

    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true "
    
    #Get the string from the respective search.
    if type == "es_query_string_search"
      search_str = es_query_string_search(qstr, options)
    elsif type == "es_terms_facet"
      search_str = es_terms_facet(qstr, options)
    end
    
    data = []
    total = nil
    case flag
      when "m"
        data, total = es_connect_md(conn_str, search_str, get_full_data) #metadata
      when "f"
        data = es_connect(conn_str, search_str, get_full_data) #full document
    end
    
    return data, total
  end
#-----------------------------------------------------------------------
  #Get string for ES pagination
  def self.es_from_and_size_str(from, size)
    retval = ""
    #puts "es_from_and_size_str ****************************************"
    #p from, size

    if from.to_i && size.to_i
      retval = "
        \"from\" : #{from.to_i}, \"size\" : #{size.to_i}
      "
    end

    retval
  end

  #Query String: uses a query parser in order to parse its content
  #Input: query string
  def self.es_query_string_search(qstr, options)
    flag = options[:flag] || 'm' #see search_type for available flags
    from = options[:from] || nil
    size = options[:size] || nil

    flag_str = search_type(flag)
    
    from_and_size_str = es_from_and_size_str(from, size)

    #add a delim if necessary
    if flag_str != ""
      flag_str += ","
    end
    if from_and_size_str != ""
      from_and_size_str += ","
    end

    return "
    {
      #{from_and_size_str}
      #{flag_str}
      \"query\" : {
         \"query_string\" : {
           \"query\" : \"#{qstr}\"
          }
        }
    }"
  end

  #############################################################################
  ##  Facet searches
  ##  TODO: Most of these are out of data; they should be refactored to return
  ##  the query body string, not the actual data (see es_terms_facet).
  #############################################################################

  #Takes a query and field string, returns terms facet information
  #Returns metadata only
  def self.es_terms_facet(qstr, options)
    qbody = "
    {
      \"query\": {\"query_string\": {\"query\":\"#{qstr}\"} },
      \"facets\": 
         {\"#{options[:sfield]}\": 
              {
                \"terms\": {\"field\" : \"#{options[:sfield]}\"}
              },
              \"type\": \"nested\"
         }
    }"

    return qbody
  end
  
  #Takes a starting and ending value plus a field, returns a range facet
  #NOTE: it is unclear how this is working
  def self.es_range_facet(qfrom, qto, sfield, flag)
    str = search_type(flag)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {#{str}
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
    case flag
      when "m"
        data = es_connect_md(conn_str, qbody) #metadata
      when "f"
        data = es_connect(conn_str, qbody) #full document
    end

    return data
  end
  
  #Takes a staring and ending date plus a date field, returns a date range facet
  def self.es_date_range_facet(qfrom, qto, sfield, flag)
    str = search_type(flag)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {#{str}
     \"query\" : {
       \"range\" : {
         \"#{sfield}\" : { \"from\" : \"#{qfrom}\", \"to\" : \"#{qto}\" }
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
    case flag
    when "m"
      data = es_connect_md(conn_str, qbody) #metadata
    when "f"
      data = es_connect(conn_str, qbody) #full document
    end

    return data
  end
  
  #Takes an interval (e.g. "day", "month") plus a date field,
  #returns a date range histogram
  #TODO: input needs date range?
  def self.es_date_histogram_facet(sfield, myinterval, qfrom, qto, flag)
    str = search_type(flag)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {#{str}
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
    case flag
    when "m"
      data = es_connect_md(conn_str, qbody) #metadata
    when "f"
      data = es_connect(conn_str, qbody) #full document
    end

    return data
  end
  
  #############################################################################
  ##  Basic Searches
  #############################################################################
  
  #Match: accept text/numerics/dates, analyzes it, and constructs a query
  #Input: query string, field
  def self.es_match_search(qstr, sfield, flag)
    str = search_type(flag)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {#{str}
     \"query\" : {
       \"match\" : { \"#{sfield}\" : \"#{qstr}\" }
       }
    }'"

    data = []
    case flag
    when "m"
      data = es_connect_md(conn_str, qbody) #metadata
    when "f"
      data = es_connect(conn_str, qbody) #full document
    end

    return data
  end
  
  #TODO?: multi match; match multiple fields?
  
  #Filtered: applies a filter to the results of another query
  #Input: query, search field, range field, staring and ending value
  def self.es_filtered_search(qstr, sfield, rfield, qfrom, qto, flag)
    str = search_type(flag)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {#{str}
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
   case flag
    when "m"
      data = es_connect_md(conn_str, qbody) #metadata
    when "f"
      data = es_connect(conn_str, qbody) #full document
    end

    return data
  end
  
  #Fuzzy Like This: find documents that are “like” provided text by
  # running it against a single field
  #Input: text, field name, max query terms
  def self.es_flt_field_search(qtext, sfield, max, flag)
    str = search_type(flag)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {#{str}
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
    case flag
    when "m"
      data = es_connect_md(conn_str, qbody) #metadata
    when "f"
      data = es_connect(conn_str, qbody) #full document
    end

    return data
  end
  
  #TODO?: More like this field?
  
  #Prefix Query: Matches documents that have fields containing terms
  # with a specified prefix (not analyzed)
  #Input: query and field strings
  def self.es_prefix_search(qstr, sfield, flag)
    str = search_type(flag)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {#{str}
     \"query\" : {
       \"prefix\" : { \"#{sfield}\" : \"#{qstr}\" }
      }
    }'"

    data = []
    case flag
    when "m"
      data = es_connect_md(conn_str, qbody) #metadata
    when "f"
      data = es_connect(conn_str, qbody) #full document
    end

    return data
  end

  #Range: Matches documents with fields that have terms within a certain range
  #Input: field string, starting and ending value
  def self.es_range_search(sfield, qfrom, qto, flag)
    str = search_type(flag)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {#{str}
     \"query\" : {
       \"range\" : {
         \"#{sfield}\" : { \"from\" : #{qfrom}, \"to\" : #{qto} }
        }
      }
    }'"
    
    data = []
    case flag
    when "m"
      data = es_connect_md(conn_str, qbody) #metadata
    when "f"
      data = es_connect(conn_str, qbody) #full document
    end
    
    return data
  end
  
  #TODO?: Span searches?
  
  #Term: Matches documents that have fields that contain a term (not analyzed)
  #Input: query and field string (query -> lower case, field -> uppercase?)
  def self.es_term_search(qstr, sfield, flag)
    str = search_type(flag)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {#{str}
     \"query\" : {
       \"term\" : { \"#{sfield}\" : \"#{qstr}\" }
      }
    }'"
    
    data = []
    case flag
    when "m"
      data = es_connect_md(conn_str, qbody) #metadata
    when "f"
      data = es_connect(conn_str, qbody) #full document
    end
    
    return data
  end
  
  #TODO: terms search (non facet?)
  
  #Wildcard: Matches documents that have fields matching a wildcard
  # expression (not analyzed)
  #Input: query and field string (query -> lower case, field -> uppercase?)
  def self.es_wildcard_search(qstr, sfield, flag)
    str = search_type(flag)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {#{str}
     \"query\" : {
       \"wildcard\" : { \"#{sfield}\" : \"#{qstr}\" }
      }
    }'"
    
    data = []
    case flag
    when "m"
      data = es_connect_md(conn_str, qbody) #metadata
    when "f"
      data = es_connect(conn_str, qbody) #full document
    end
    
    return data
  end
  
  #############################################################################
  ##  Utility Testing Methods
  ##  Methods for testing only.
  #############################################################################
  
  #SAS for testing and debuging ONLY!
  def self.es_test(qstr, sfield, flag)
    conn_str = "/#{get_database_name}/#{get_database_name}/_search?pretty=true -d '"
    qbody = "
    {#{str}
     \"query\":{
       \"match\":{ \"#{sfield}\" : \"#{qstr}\" }
      }
    }'"
    
    data = []
    data = es_connect_md(conn_str, qbody) #metadata
    
    return data
  end

end
