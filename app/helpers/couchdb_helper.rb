module CouchdbHelper

  def is_couchdb_running?(host = "localhost", port = "5984", username = nil, 
                          password = nil, https = false
                          )
    begin
      if https
        conn_str = "https://"
      else
        conn_str = "http://"
      end
      
      if username != nil and password != nil
        conn_str += "#{username}:#{password}@"
      end
      
      conn_str += "#{host}:#{port}/"
      
      CouchRest.get conn_str
      return true
    rescue
      return false
    end
  end

  def get_couchrest_database(host = "localhost", port = "5984", username = nil, 
                          password = nil, https = false
                          )
    if https
      conn_str = "https://"
    else
      conn_str = "http://"
    end
    
    if username != nil and password != nil
      conn_str += "#{username}:#{password}@"
    end
    
    conn_str += "#{host}:#{port}/"
    
    return CouchRest.database!(conn_str)
  end
end