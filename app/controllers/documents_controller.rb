class DocumentsController < ApplicationController
  require 'will_paginate/array'
  
  include DocumentsHelper
  include VizHelper
  helper_method :sort_column, :sort_direction
    
  before_filter :autologin_if_dev
  before_filter :authenticate_user!
  before_filter :require_permissions
  load_and_authorize_resource
  
  def require_permissions
    if params.include?("id")
      document = Document.find(params[:id])
#=begin
      if not doc_is_viewable(document, current_user)

        flash[:error] = "Document not found, or you do not have permissions for this action. ".html_safe
        if document
          flash[:error] += view_context.mail_to document.user.email, "Request access via email.", subject: "Requesting access to #{document.name}"
        end

        redirect_to collections_path
      end
#=end
    end
  end

  # GET /documents
  # GET /documents.json
  def index
    respond_to do |format|
    #  format.html # index.html.erb
    #  format.json { render json: @documents }
    # This will die if not asekd by our dataTables, because we're using params[:collection_id]
      format.json { render json: DocumentsMainDatatable.new(view_context, current_user)}
    end
  end
  
  #TODO: re-implement with search
  def index_search
    return
    #Search for data if search comes in
    if params[:search] != nil
      #Delete any temp search docs so we don't search them too 
      Document.destroy_all(:name => ENV['temp_search_doc'])
     
      #start recording run time
      data_stime = Time.now() #start time
     
      d = document_search_data_couch(params[:search], params.has_key?("lucky_search"))
      data_etime = Time.now() #end time
      data_ttime = data_etime - data_stime #total time
      
      #start recording run time
      doc_stime = Time.now() #start time
      
      c=Collection.find_or_create_by_name("Recent Searches")
      c.save
      
      @temp_search_document = Document.new
      @temp_search_document.name = ENV['temp_search_doc']
      @temp_search_document.collection = c
      @temp_search_document.stuffing_data = d
      @temp_search_document.stuffing_is_search_doc = TRUE
      @temp_search_document.save
    
#TODO: taking out document searching for now, because it is so slow!  
=begin      
      doc_etime = Time.now() #end time
      doc_ttime = doc_etime - doc_stime #total time
          
      @documents = Document.search(params[:search]).order(sort_column + " " + sort_direction).paginate(:per_page => 5, :page => params[:page])

      flash[:notice]="Searched data in #{data_ttime} seconds, searched document names in #{doc_ttime}."
=end
      @documents = []
      flash[:notice]="Searched data in #{data_ttime} seconds."
    else
        @documents = Document.all.paginate(:per_page => 5, :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @documents }
    end
  end
  
  # PUT /documents/1/doc_md_edit
  def doc_md_edit
    md_table = params[:md_table]  #metadata table from MD editor
    document = Document.find(params[:id])
    mdsave_params = params
    edited_suc = false
    
    if (document != nil)
      edited_suc = metadata_save(md_table, document)
    end
    
    respond_to do |format|
      if (edited_suc == true)
        format.html { redirect_to document, notice: "Metadata saved" }
        #format.js { render :text => "Metadata saved!", notice: "Metadata saved!"}
        format.js { render :text => mdsave_params[:value], notice: "Metadata saved!"}
        format.json { head :ok }
      else
        format.html { render action: "show" }
        format.js { render :text => "Error: metadata could not be saved",
          notice: "Metadata not saved!" }
        format.json { render json: document.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /documents/1/show_data
  def show_data
    @document = Document.find(params[:id])
    authorize! :show_data, @document if params[:id]
    get_menu()
    get_doc_info()
    get_show_data()

    #For non datatables view
    current_page = params[:page]
    per_page = params[:per_page] || 25 # could be configurable or fixed in your app
    
    @paged_sdata = []
    if @sdata != nil
      @paged_sdata = @sdata.paginate({:page => current_page, :per_page => per_page})
    end
    
    #Displays a download link for raw unfilterable files.
    @raw_file_link = nil
    if (@document.stuffing_raw_file_url != nil)
      @raw_file_link = @document.stuffing_raw_file_url
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @paged_sdata }
    end
  end

  # GET /documents/1
  # GET /documents/1.json
  def show
    @document = Document.find(params[:id])
    get_menu()
    get_doc_info()
    get_metadata()
    @notes = @document.stuffing_notes
    
    @doc_collection = Collection.find(@document.collection_id)
    
    @job = nil
    if @document.job_id != nil
      begin ActiveRecord::RecordNotFound
        @job = Job.find(@document.job_id)
      rescue
        @job = false
        puts "INFO: Job with id #{@document.job_id} for Document #{@document.name} no longer exists." 
      end
    end
=begin
    #For datatables view
    current_page = params[:page]
    per_page = params[:per_page] # could be configurable or fixed in your app

    @paged_sdata = []
    if @sdata != nil
      @paged_sdata = @sdata.paginate({:page => current_page, :per_page => 20})
    end
=end
    respond_to do |format|
      format.html # show.html.erb
      #format.json { render json: DocumentsDatatable.new(view_context, @document) }
    end
  end

  #Shows the JSON like the show() method would normally do. show() is doing datatable
  # JSON, so this method will do the normal JSON.
  def show_simple_json
    @document_object = Document.find(params[:id]).as_json

    job = Job.find(@document_object["job_id"].to_i)

    #Let's add some extra stuff, like some job data, for JS.
    @document_object['job_succeeded'] = job[:succeeded] \
      rescue @document_object['job_succeeded'] = false
    @document_object['job_waiting'] = job[:waiting] \
      rescue @document_object['job_waiting'] = false
    @document_object['job_started'] = job[:started] \
      rescue @document_object['job_started'] = false
    @document_object['job_error_or_output'] = job.get_error_or_output \
      rescue @document_object['job_error_or_output'] = false

    respond_to do |format|
      format.json { render json: @document_object }
    end
  end
  
  # GET /documents/new
  # GET /documents/new.json
  def new
    @document = Document.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @document }
    end
  end

  # GET /documents/1/edit
  def edit    
    @document = Document.find(params[:id])

    @colnames = get_data_colnames(@document.stuffing_data)
    
    @colab_users = []
    User.all.each do |user|
      if user.documents.include?(@document)
        @colab_users << user
      end
    end
  end

  def edit_text
    @document = Document.find(params[:id])
  end
  
  def edit_notes
    @document = Document.find(params[:id])
  end

  # POST /documents
  # POST /documents.json
  def create
    @document = Document.new(params[:document])
    @document.stuffing_data = []
    @document.user = current_user

    #Hack for now - add all column keys to primary keys for search
    @document.stuffing_primary_keys = get_data_colnames(@document.stuffing_data)

    respond_to do |format|
      if @document.save
        format.html { redirect_to @document, notice: 'Document was successfully created.' }
        format.json { render json: @document, status: :created, location: @document }
      else
        format.html { render action: "new" }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /documents/1
  # PUT /documents/1.json
  def update
    @document = Document.find(params[:id])

    suc_msg = 'Document was successfully updated. '
      
    #if we're in document text edit mode, or notes edit mode
    if (params.include?("document")) and (params["document"].include?("post")) and (params["document"]["post"] == "edit_text")
      @document.stuffing_text = params["document"]["stuffing_text"]
      update_suc = @document.save
    elsif (params.include?("document")) and (params["document"].include?("post")) and (params["document"]["post"] == "edit_notes")
      @document.stuffing_notes = params["document"]["stuffing_notes"]
      update_suc = @document.save
    else
      #Add doc to project
      if params.include?("proj") and params[:proj].include?("id") and params[:proj][:id] != ""
        project = Project.find(params[:proj][:id])
        if (project != nil)
          add_project_doc(project, @document) #call to document helper, adds doc to project
        end
      end

      user = User.where(:id => params[:new_user_id]).first
=begin
      #Add collaborator
      if user != nil
        if not user.documents.include?(@document)
          user.documents << @document
          user.save
        end
      end
      
      #Remove collaborators
      if params[:colab_user_ids]
        User.find(params[:colab_user_ids]).each do |user|
          user.documents.delete(@document)
        end
      end
=end

      #Update other attributes
      if (@document.user_id == current_user.id)
        update_suc = @document.update_attributes(params[:document])
      else
        #needed becuase update will drop collection id if an editor tries to use a filter
        coll_id = @document.collection_id
        update_suc = @document.update_attributes(params[:document])
        update_suc = @document.update_attributes(:collection_id => coll_id)
      end

      #Filter / Validate
      if ( params.include?("post") and params[:post].include?("ifilter_id") and params[:post][:ifilter_id] != "" )
        #f = Ifilter.find(params[:post][:ifilter_id])
        f = get_ifilter(params[:post][:ifilter_id].to_i)

        #don't let validate auto-filter
        if f != nil
          suc_msg += 'Validation filter started; refresh your browser to check for completion. '

          job = Job.new(:description => "Document #{@document.name} validation")
          job.save
          job.submit_job(current_user, @document, {:ifilter_id => f.id})
        end
      end
    end #end if in text edit mode, else...

    respond_to do |format|
      if update_suc
        format.html { redirect_to @document, notice: suc_msg }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  #Does the update for unvalidated/unfiltered documents with changes to text.
  def update_text

    respond_to do |format|
      if update_suc
        format.html { redirect_to @document, notice: suc_msg }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /documents/1
  # DELETE /documents/1.json
  def destroy
    @document = Document.find(params[:id])
    upload_remove(@document)  #Removes upload record if file is deleted
    @document.destroy

    respond_to do |format|
      format.html { redirect_to collections_path }
      format.json { head :ok }
    end
  end
  
  #Creates new doc data based on some predefined methods
  def manip
    d = Document.find(params[:id])
    colname = params[:manip_colname]
    @document = Document.create(
                                :name => "#{d.name}_manip", 
                                :collection => d.collection,
                                :stuffing_data => get_data_map(d, colname))
    
    @sdata = @document.stuffing_data
    @msdata = get_document_metadata(@document)
    
    current_page = params[:page]
    per_page = params[:per_page] # could be configurable or fixed in your app
    @paged_sdata = @sdata.paginate({:page => current_page, :per_page => 20})                            
    
    chart = Chart.find_by_document_id(@document)
    @chart = chart || Chart.find(newchart({:document_id => @document}))
    
    render "show"
  end
  
  #Downloads a single raw/unfilterable file
  # GET /documents/download_raw/1
  def download_raw
    document = Document.find(params[:id])
    authorize! :download_raw, document
    upload = Upload.find( document.stuffing_upload_id )
    
    send_file upload.upfile.path, 
     :filename => upload.upfile_file_name, 
     :type => 'application/octet-stream'
  end

  def download
    redirect_to csv_export_path(params[:id], :format => :csv)
  end
  
  
  def search_test
    d = document_search_data_couch("test")

    @temp_search_document = Document.find_or_create_by_name(ENV['temp_search_doc'])
    #TODO: set to internal (user?) collection
    #@temp_search_document.collection = c
    @temp_search_document.stuffing_data = d
    @temp_search_document.save
    
    @documents = Document.search(params[:search]).order(sort_column + " " + sort_direction).paginate(:per_page => 5, :page => params[:page])
    
    render "index"
  end
  
  def sort_column
    Document.column_names.include?(params[:sort]) ? params[:sort] : "name"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
  
  def filter
    @document = Document.find(params[:id])
    
    respond_to do |format|
      format.html { redirect_to @document }
      format.json { render json: @document.stuffing_data }
    end
  end
end
