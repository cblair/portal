class DocumentsController < ApplicationController
  require 'will_paginate/array'
  require 'spawn'
  
  include DocumentsHelper
  include VizHelper
  helper_method :sort_column, :sort_direction
    
  before_filter :autologin_if_dev
  before_filter :authenticate_user!
  before_filter :require_permissions
  
  
  def require_permissions
    if params.include?("id")
      document = Document.find(params[:id])
      
      if not doc_is_viewable(document, current_user)
        flash[:error] = "Document not found, or you do not have permissions for this action."
        redirect_to collections_path
      end
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

  # GET /documents/1
  # GET /documents/1.json
  def show
    @document = Document.find(params[:id])
    
    @sdata = @document.stuffing_data
    @msdata = get_document_metadata(@document)
    
    current_page = params[:page]
    per_page = params[:per_page] # could be configurable or fixed in your app
    
    @paged_sdata = []
    if @sdata != nil
      @paged_sdata = @sdata.paginate({:page => current_page, :per_page => 20})
    end
    
    chart = Chart.find_by_document_id(@document)
    @chart = chart || Chart.find(newchart({:document_id => @document}))
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: DocumentsDatatable.new(view_context, @document) }
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
    
    user = User.where(:id => params[:new_user_id]).first
   
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

    #Update other attributes
    update_suc = @document.update_attributes(params[:document])

    #Filter / Validate
    if ( params.include?("post") and params[:post].include?("ifilter_id") and params[:post][:ifilter_id] != "" )
      #f = Ifilter.find(params[:post][:ifilter_id])
      f = get_ifilter(params[:post][:ifilter_id].to_i)

      #don't let validate auto-filter
      if f != nil
        suc_msg += 'Validation filter started; refresh your browser to check for completion. '

        #spawn_block do
          validate_document_helper(@document, f)
        #end
      end
    end

    #Add primary keys
    #@document.stuffing_primary_keys = params[:primary_keys]
    #Hack for now - add all column keys to primary keys for search
    @document.stuffing_primary_keys = get_data_colnames(@document.stuffing_data)

    #Indexes
    #safsa

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
    @document.destroy

    respond_to do |format|
      format.html { redirect_to documents_url }
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
  
  
  def pub_priv_doc
    @document = Document.find(params[:id])
    
    if params.include?("public")
      if params[:public] == "true"
        @document.public = true
      else
        @document.public = false
      end
    end

    respond_to do |format|
      if @document.save
        format.html { redirect_to @document, notice: 'Document permissions were successfully changed.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end
end
