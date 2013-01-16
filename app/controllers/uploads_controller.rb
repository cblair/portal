class UploadsController < ApplicationController
  require 'csv'
  require 'spawn'
  include DocumentsHelper
  include IfiltersHelper
  
  # GET /uploads
  # GET /uploads.json
  def index
    @uploads = Upload.all

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
      #User
      c.user = current_user
      c.save
    elsif c_text != ""
      c=Collection.new(:name => c_text)
      #User
      c.user = current_user
      c.save
    else
      c = nil
    end
    
    #File stuff
    #fname=params[:dump][:file].original_filename
    fname=params[:upload][:upfile].original_filename
    
    #filter
    f=nil
    if ( params.include?("post") and params[:post].include?("ifilter_id") )
      f=Ifilter.find(params[:post][:ifilter_id])
    end
    
    #spawn_block do
      #Parse file into db
      if @upload.upfile.content_type == "application/zip"
        #save_zip_to_documents(fname, uploaded_file, c, f)
        save_zip_to_documents(fname, @upload, c, f)
      else #hopefully is something like a "text/plain"
        #save_file_to_document(fname, uploaded_file.tempfile, c, f)
        save_file_to_document(fname, @upload.upfile.path, c, f) 
      end
    #end

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
      format.html { redirect_to uploads_url }
      format.json { head :ok }
    end
  end
end
