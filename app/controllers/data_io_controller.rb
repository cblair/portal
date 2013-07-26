class DataIoController < ApplicationController
  require 'csv'
  require 'zip/zip'
  require 'tmpdir'
  include DocumentsHelper
  include IfiltersHelper

  #before_filter :autologin_if_dev
  before_filter :authenticate_user!

  def index

  end

  def js_upload
    respond_to do |format|
      format.js
    end
  end
  
  #Note - this method is no longer used; the jQuery upload form uses the 
  #       new upload controller  
  def csv_import
    #start recording run time
    stime = Time.now() #start time
    
    #Collection - find / create
    c_text = params[:dump][:collection_text]
    if c_text == nil
      #take the collection from the select menu
      c_id = params[:dump][:collection_id]
      c=Collection.find(params[:dump][:collection_id])
    else
      #create a new collection at the root
      #c=Collection.new(:name => ctext)

      #if the ctext is a new collection, all the file will go under this collection
      # But if a collection already exists, everything will go under there, which may
      # not be exactly what the user wanted
      c = Collection.find_or_create_by_name(:name => ctext)
    end
    
    #Project - find the project by id
    #p=Project.find(params[:dump][:project_id])
    #puts("*** project = #{p.name}") #debug, triggers on list selection
    #User
    c.user = current_user
    c.save
    
    #File stuff
    fname=params[:dump][:file].original_filename
    
    #filter
    filter_id=params[:post][:ifilter_id]
    f=nil
    if filter_id != ""
      f=Ifilter.find(filter_id)
    end
    
    upload = Upload.create(:name => fname, :upfile => params[:dump][:file])
    
    #spawn_block do
      #Parse file into db
      if upload.upfile.content_type == "application/zip"
        #save_zip_to_documents(fname, uploaded_file, c, f)
        save_zip_to_documents(fname, upload, c, f)
      else #hopefully is something like a "text/plain"
        #save_file_to_document(fname, uploaded_file.tempfile, c, f)
        save_file_to_document(fname, upload.upfile.path, c, f) 
      end
    #end

    etime = Time.now() #end time
    ttime = etime - stime #total time
    
    #flash[:notice]="Collection '#{c_text}' import successful,  #{@document.stuffing_data.count} new rows added to data base in #{ttime}"
    flash[:notice]="Files uploaded successfully. "
    redirect_to :controller => "collections"

    #flash[:notice] +="Collection '#{c_text}' import successful."

    #redirect_to :controller => "documents", :action => "show", :id => @document[:id]
  end
  

  def csv_export
    #Export scaffold type - Collection or Document
    stype = params[:stype]

    #Create zip
    zip_fname = "hatch_data_io"
    temp_zip = Tempfile.new(zip_fname)
    
    Zip::ZipOutputStream.open(temp_zip.path) do |zipfile|
      parent_dir_path = ''
      
      #Get doc_list
      if stype == "Document"
        document = Document.find(params[:id])
        doc_list = {document => nil}
        zip_doc_list([], zipfile, doc_list)
      elsif stype == "Collection"
        collection = Collection.find(params[:id])
        doc_list = {}
        collection.documents.each do |key|
          doc_list[key] = nil
        end
        recursive_collection_zip([], zipfile, collection)
        
      #TODO: else error  
      end
    end
          
    #Send the zip back, and cleanup
    send_file temp_zip.path,  :type => 'application/zip',
                              :disposition => 'attachment',
                              :filename => zip_fname
    temp_zip.close
  end
end
