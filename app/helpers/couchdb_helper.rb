module CouchdbHelper

  def is_couchdb_running?
    begin
      CouchRest.get "http://localhost:5984/"
      return true
    rescue
      return false
    end
  end
end