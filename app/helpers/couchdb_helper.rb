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


  def get_http_connection_hash
    host     = Portal::Application.config.couchdb['COUCHDB_HOST']
    port     = Portal::Application.config.couchdb['COUCHDB_PORT']
    username = Portal::Application.config.couchdb['COUCHDB_USERNAME']
    password = Portal::Application.config.couchdb['COUCHDB_PASSWORD']
    https    = Portal::Application.config.couchdb['COUCHDB_HTTPS']

    retval = {:username => false, :password => false}

    if https
      retval[:https] = true
    else
      retval[:https] = false
    end
    
    if (username and (!username.empty?) and password and (!password.empty?))
      retval[:username] = username
      retval[:password] = password
    end
    
    retval[:host] = host
    retval[:password] = password
    retval[:port] = port

    return retval
  end


  def get_database_name
    "#{File.basename(Rails.root)}_#{Rails.env}"
  end
end