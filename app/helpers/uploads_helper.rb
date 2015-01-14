module UploadsHelper

  #Adds upload id to document in couch.
  def upload_id_save(doc_id)
    if (doc_id == nil)
      puts "###ERROR: Document has no ID, can't save upload ID. ###"
      return false
    end

    document = Document.find(doc_id)  #TODO: exception handeling?
    document.stuffing_upload_id = @upload.id
    document.save
  end
#-----------------------------------------------------------------------

  #Deletes file upload record.
  def upload_remove(doc)
    if (doc == nil)
      puts "### ERROR: Document is nil, can't delete upload. ###"
      return false
    end

    if (doc.stuffing_upload_id != nil)
      begin
        upload = Upload.find(doc.stuffing_upload_id)
        upload.destroy  #Upload exists, delete upload.
      rescue ActiveRecord::RecordNotFound
        #Document should be deleted regardless if upload record exists
        puts "### Upload record not found, skipping delete. ###"
        return false
      end
      puts "### Upload deleted. ###"
    else
      puts "### Upload ID in document not found, skipping delete. ###"
    end

  end
#-----------------------------------------------------------------------

  #Checks document, if validation was successful deletes related upload record.
  def upload_remove_on_validate(doc)
    if (doc == nil)
      puts "### ERROR: Document is nil, can't remove upload'. ###"
      return false
    end

    if (doc.validated == nil or doc.validated == false)
      puts "### Document not validated, skipping upload delete. ###"
      return true
    end
    
    if (doc.validated == true)
      puts "### Document is validated, upload ready for delete. ###"
      upload_remove(doc)
      doc.stuffing_upload_id = nil
      doc.save
    end
    
    return true
  end
#-----------------------------------------------------------------------

  #Submit job for filtering, upload must have an associated existing document.
  #Args: doc_id: document id, f: filter id
  def filter_upload(doc_id, f)
  
    if (f.id == -4 or f.id == -5)
      puts "Don't filter this file.'"  #Do nothing.
      return 
    end

    if (doc_id != nil)
      document = Document.find(doc_id)
      validate_document(document, f)
    end
  end
#-----------------------------------------------------------------------

  #Saves raw file, no filtering, no data saved to couch.
  #Args fname: file name [string], file: path [string] (deleted),
  # c: collection, f: filter (should be nil)
  def save_file_no_filter(fname, c, f, user=current_user)
    status = false
    file = @upload.upfile.path  #Not needed for raw file?
    filter = get_ifilter(f.to_i)

    puts "### Saving Non-Filterable file... ###"

    if (fname == nil or file == nil)
      log_and_print "WARN: file name or object was nil, can't save to document"
      return false
    end
    stime = Time.now()
    
    #Save file name to Document, save document.
    @document=Document.new
    @document.name=fname
    @document.collection=c
    #@document.stuffing_metadata = [ { "HatchFilter" => "No-filter (pre-defined))" } ]
    @document.stuffing_metadata = [ { "HatchFilter" => filter.name } ]
    @document.stuffing_raw_file_url = @upload.upfile.url

    @document.user = user
    document_id = nil

    begin
      status = @document.save
      document_id = @document.id
      etime = Time.now()
      log_and_print "INFO: Saved document #{fname} in #{etime - stime} seconds."
    rescue RestClient::Conflict
      log_and_print "ERROR: 409 Conflict, couldn't save document. ActiveRecord and CouchDB databases may be out of sync."
      return false
    rescue RestClient::ResourceNotFound
      log_and_print "ERROR: 404, couldn't save document. ActiveRecord and CouchDB databases may be out of sync."
      return false
    rescue RestClient::BadRequest
      log_and_print "ERROR: Couldn't save document #{fname}, probably because of a parse error."

      log_and_print "ERROR: More parse information: "
      log_and_print @document.stuffing_text
      return false
    rescue RestClient::InternalServerError
      log_and_print "ERROR: some other saving problem happend with document #{fname}."
      return false
    end

    return status, document_id
  end
  
end
