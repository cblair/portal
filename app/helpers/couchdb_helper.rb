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
      
      logger.info "Using couchdb: #{conn_str}"
      
      CouchRest.get conn_str
      return true
    rescue
      return false
    end
  end
end