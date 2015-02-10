class UploadsController < ApplicationController
  require 'csv'
  include DocumentsHelper
  include CollectionsHelper
  include IfiltersHelper
  include MetaformsHelper
  include UploadsHelper
  before_filter :require_permissions
  
  load_and_authorize_resource
  
  def require_permissions
    if params.include?("id")
      upload = Upload.find(params[:id])
      
      if upload.user != current_user
        flash[:error] = "Upload not found, or you do not have permissions for this action."
        redirect_to collections_path
      end
    end
  end

  # GET /uploads/uploads_list
  # GET /uploads/uploads_list.json
  def uploads_list
    #Action for viewing uploads with datatables

    respond_to do |format|
      format.html
      format.json { render json: UploadsDatatable.new(view_context,current_user) }
    end
  end

  # GET /uploads
  # GET /uploads.json
  def index
    current_page = params[:page]
    per_page = params[:per_page] || 10 # could be configurable or fixed in your app
    @uploads = Upload.where(:user_id => current_user.id).order(:upload_type, :upfile_file_name).paginate({:page => current_page, :per_page => per_page})

    respond_to do |format|
      format.html # index.html.erb
      #format.json { render json: @uploads }
      format.json { render json: @uploads.map{|upload| upload.to_jq_upload } }
      format.js { render json: @uploads.map{|upload| upload.to_jq_upload } }
    end
  end

  # GET /uploads/1
  # GET /uploads/1.json
  def show
    @upload = Upload.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @upload }
    end
  end

  # GET /uploads/new
  # GET /uploads/new.json
  def new
    @upload = Upload.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @upload }
    end
  end

  # GET /uploads/1/edit
  def edit
    @upload = Upload.find(params[:id])
  end

  # POST /uploads
  # POST /uploads.json
  def create
    #@upload = Upload.new(params[:upload])
    @upload = Upload.create(params[:upload])

    #File stuff
    #fname=params[:dump][:file].original_filename
    fname=params[:upload][:upfile].original_filename

    #20 MB max size
    max_size = 20000000
    file_size = params[:upload][:upfile].size
    if file_size > max_size
      respond_to do |format|
        error_message = "File size #{file_size} > #{max_size}"
        error_json = [  
                       {
                          :error => error_message,
                          :name  => fname,
                          :size  => file_size
                        }
                      ]
        format.html {render action: "new", notice: error_message}

        #We always return the 'created' status, or the client will overwrite our custom
        # error message with the one for the error (i.e. 
        # 422 "unprocessable due to semantic errors")

        #format.json {render json: error_json, status: :created }
        format.js   {render json: error_json, status: :created }
      end

      return
    end
    
    @upload.user = current_user  #not working? No user field?
    #@upload.user_id = current_user.id
    
    f=nil  #filter

    #start recording run time
    stime = Time.now() #start time
    
    #Collection - find / create
    c_id = nil
    c_text = ""

    if ( params.include?("post") and params[:post].include?("collection_text") and params[:post]["collection_text"] != "" )
      c_text = params[:post][:collection_text]
    end
    
    if ( params.include?("post") and params[:post].include?("collection_id") and params[:post]["collection_id"] != "" ) 
      c_id = params[:post]["collection_id"].to_i
    end
    
    if c_id != nil
      c = Collection.find(c_id)
    elsif c_text != ""
      #c=Collection.new(:name => c_text)

      #if the ctext is a new collection, all the files will go under this collection
      # But if a collection already exists, everything will go under there, which may
      # not be exactly what the user wanted
      c = Collection.find_or_create_by_name(:name => c_text)
    else
      c = Collection.find_or_create_by_name(:name => "(blank)")
    end
    
    #User
    c.user = current_user
    c.save

    status = nil
    document_id = nil
    filter_id = nil

    if (params.include?("post") and params[:post]["ifilter_id"] )
      filter_id = params[:post]["ifilter_id"].to_i  #Gets filter id for non-filterable file
    end

    #Parse file into db - these ignore the f filter
    if @upload.upfile.content_type == "application/zip"
      save_zip_to_documents(fname, @upload, c, f)
    elsif (filter_id != nil and filter_id == -4)  #Non-filterable data file, doesn't' save in couch
      @upload.upload_type = "binary"
      status, document_id = save_file_no_filter(fname, c, filter_id)
      upload_id_save(document_id)
    elsif (filter_id != nil and filter_id == -5)  #Non-filterable note file, doesn't' save in couch
      @upload.upload_type = "note"  #Do nothing extra because its a note
      status = true
    else #hopefully is something like a "text/plain"
       status, document_id = save_file_to_document(fname, @upload.upfile.path, c, f)
       upload_id_save(document_id)
    end

    #Filter - now, if we got a filter, start validation jobs
    if ( params.include?("post") and params[:post].include?("ifilter_id") and (params[:post]["ifilter_id"].to_i != 0))

      if (status == true)
        f = get_ifilter(params[:post]["ifilter_id"].to_i)  #Gets list of filters
        filter_upload(document_id, f)
      end
    end

    #Metaform processing  #TODO: make this a job?
    if ( params.include?("post") and params[:post].include?("metaform_id") and params[:post]["metaform_id"] != "" ) 
      mf_id = params[:post]["metaform_id"].to_i
      add_document_metaform(document_id, mf_id)
    end

    etime = Time.now() #end time
    ttime = etime - stime #total time
    
    flash[:notice]="Files uploaded successfully. "
    #redirect_to :controller => "collections"

    respond_to do |format|
      if @upload.save
        #format.html { redirect_to @upload }
        format.html {
          render :json => [@upload.to_jq_upload].to_json,
          :content_type => 'text/html',
          :layout => false
        }
        format.json { render json: [@upload.to_jq_upload].to_json, status: :created, location: @upload }
        format.js { render json: [@upload.to_jq_upload].to_json, status: :created, location: @upload }
      else
        format.html { render action: "new" }
        format.json {  render json: @upload.errors, status: :unprocessable_entity }
        format.js {  render json: @upload.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /uploads/1
  # PUT /uploads/1.json
  def update
    @upload = Upload.find(params[:id])

    @upload.user = current_user

    respond_to do |format|
      if @upload.update_attributes(params[:upload])
        format.html { redirect_to @upload, notice: 'Upload was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @upload.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /uploads/1
  # DELETE /uploads/1.json
  def destroy
    @upload = Upload.find(params[:id])

    @upload.upfile = nil
    @upload.save

    @upload.destroy

    respond_to do |format|
      #format.html { redirect_to uploads_url }
      format.html { redirect_to uploads_list_url }
      format.json { head :ok }
    end
  end
  
  #Downloads a non-document uploaded file.
  # GET /documents/download_note/1
  def download_upload
    upload = Upload.find(params[:id])
    
    send_file upload.upfile.path,
     :filename => upload.upfile_file_name, 
     :type => 'application/octet-stream'
  end
end
