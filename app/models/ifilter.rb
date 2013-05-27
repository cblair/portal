class Ifilter < ActiveRecord::Base
  require 'stuffing'
  
  attr_accessible :name, :regex, :stuffing_headers
  
  stuffing  :host     => Portal::Application.config.couchdb['COUCHDB_HOST'], 
            :port     => Portal::Application.config.couchdb['COUCHDB_PORT'],
            :username => Portal::Application.config.couchdb['COUCHDB_USERNAME'],
            :password => Portal::Application.config.couchdb['COUCHDB_PASSWORD'],
            :https    => Portal::Application.config.couchdb['COUCHDB_HTTPS']

  def get_ifilter_headers()
    retval = []
    begin
      if self.stuffing_headers != nil
        retval = self.stuffing_headers
      end
    rescue
      retval = []
    end
    
    return retval
  end


  def get_ifiltered_row(row)
    retval = []

    if (row == nil)
      log_and_print "WARN: ifilter or row was nil during parsing"
      return row
    end
    
    t = row
    if (t.is_a? Array or t.is_a? Hash)
      t = t.join(' ')
    end

    matches = /#{self.regex}/.match(t)

    #if regex finds matches, populate 
    if matches != nil
      matches.captures.each do |mtext|
        retval << mtext
      end
    end
    
    return retval
  end
end