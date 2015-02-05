class CollectionsController < ApplicationController
  include CollectionsHelper
  include DocumentsHelper

  require 'will_paginate'
  
  #before_filter :authenticate_user!
  before_filter :require_permissions
  load_and_authorize_resource
  
  def require_permissions
    if not authenticate_user!
      redirect_to home_path
    elsif ( params.include?("collections") and params.include?("id") )
      collection = Collection.find(params[:id])

      if not collection_is_viewable(collection, current_user)
        flash[:error] = "Collection not found, or you do not have permissions for this action."
        redirect_to collections_path
      end

    end
  end
  
  # GET /collections
  # GET /collections.json
  def index
    #@collections = Collection.all
    @root_collections = []
    
    #filter by parent collection id if requested
    if params.include?('parent_id')
      #@all_collections = Collection.where(:collection_id => params['parent_id'].to_i)
      #TODO: ancestry?
    else
      #only root collections
      #TODO
      #@all_collections = Collection.where(:collection_id => nil).order('name')
      @all_collections = Collection.roots.order('name')
    end
    
    #add additional data, mostly for json requests
    @all_collections.each do |c|
      c.validated = collection_is_validated(c)
    end

    #filter for permission
    @all_collections.each do |c|
      if collection_is_viewable(c, current_user)
        @root_collections << c
      end
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @root_collections }
    end
  end

  # GET /collections/1
  # GET /collections/1.json
  def show    
    @collection = Collection.find(params[:id])

    #@documents = Document.where(:collection_id => @collection.id).paginate(:per_page => 5, :page => params[:page])
    @documents_all = Document.where(:collection_id => @collection.id)

    @documents = []
    @documents_all.each do |doc|
      if doc_is_viewable(doc, current_user)
        @documents << doc
      end
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @collection }
    end
  end

  # GET /collections/new
  # GET /collections/new.json
  def new
    @collection = Collection.new(:parent_id => params[:parent_id])

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @collection }
    end
  end

  # GET /collections/1/edit
  def edit
    @collection = Collection.find(params[:id])
    @remove_notes_ids = remove_note_list()
    #Gets projects where the user is an editor
    #projs = Project.find( Collaborator.where(user_id: current_user.id).pluck(:project_id) )
    #@proj_ids = projs.collect{|proj| [ proj.name, proj.id ]}
  end

  # POST /collections
  # POST /collections.json
  def create
    @collection = Collection.new(params[:collection])
    @collection.user = current_user

    #Checks collection for parent, inherits permissions
    if ( params[:collection].include?("parent_id") and params[:collection]["parent_id"] != "" )
      parent_collection = Collection.find(params[:collection]["parent_id"])
      inherit_collection(parent_collection)
    else
      puts "### Collection has no parent"
    end

    respond_to do |format|
      if @collection.save
        #format.html { redirect_to @collection, notice: 'Collection was successfully created.' }
        format.html { redirect_to collections_path, notice: 'Collection was successfully created.' }
        #format.json { render json: @collection, status: :created, location: @collection }
        format.json { render json: collections_path, status: :created, location: collections_path }
      else
        format.html { render action: "new" }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /collections/1
  # PUT /collections/1.json
  def update
    @collection = Collection.find(params[:id])
    
    #Parent collection stuff
    parent_child_violation = false
    access_violation = false
    if params.include?("collection") and params[:collection].include?("parent_id") and params[:collection]["parent_id"] != ""
      parent_collection = Collection.find(params[:collection]["parent_id"])
      
      if (parent_collection.user_id != @collection.user_id)
        access_violation = true
        
      else
        #if !collection_is_parent(@collection, parent_collection)
        if !parent_collection.ancestors.include?(@collection)
          @collection.parent_id = parent_collection.id
          
          #inherits project (and permissions) of parent by default
          inherit_collection(parent_collection)
        else
          parent_child_violation = true
        end
      end #if parent
    end #if params
    
    #Update
    #do this now, so the spawn doesn't PG:Error b/c spawned code has locked @colllection
    update_collection_attrs_suc = false
    if (not parent_child_violation and not access_violation)
      update_collection_attrs_suc = @collection.update_attributes(params[:collection])
    end

    #Validation
    if (params.include?("post") and params[:post].include?("ifilter_id") and params[:post][:ifilter_id] != "" )
      f = get_ifilter( params[:post][:ifilter_id].to_i )

      validate_collection_helper(@collection, f)
    end
    
    #Add metadata from a metaform
    if (params.include?("post") and params[:post].include?("metaform_id") and params[:post][:metaform_id] != "" )
      add_collection_metaform(@collection, params[:post][:metaform_id].to_i)
    end

    #Add to my project
    if (params.include?("proj") and params[:proj].include?("id") and params[:proj][:id] != "" )
      project = Project.find( params[:proj][:id] )
      add_project_col(project, @collection) #call to collection helper, adds collection to project
    end
    
    #Add selected upload as a note to the collection
    if (params.include?("note") and params["note"].include?("upload_id") and (!params["note"]["upload_id"].blank?) )
       add_note_collection( params["note"]["upload_id"] )
    end

    if (params.include?("remove_ids") and (!params["remove_ids"].blank?) )
      remove_notes_collection( params["remove_ids"] ) #Remove notes
    end

=begin
    #Add to other project (as editor)
    if (params.include?("ed_proj") and params[:ed_proj].include?("pro_id") and params[:ed_proj][:pro_id] != "" )
      project = Project.find( params[:ed_proj][:pro_id] )
      add_project_col(project, @collection) #from collection helper
    end
=end
    #Recursive remove from project
    if params.include?("remove_project")
      params["remove_project"].each do |k,v|
        if v.to_i == 1
          project = Project.find(k.to_i)
          @collection.projects.delete project
          @collection.descendants.each do |c|
            if !c.projects.empty?
              c.projects.delete project
            end
          end
        end
      end
    end

    respond_to do |format|
      if access_violation
        @collection.errors.add(:base, "You are not authorized to do that.")
        format.html { render action: "edit" }
      elsif parent_child_violation 
        #flash[:error] =  "Warning: cannot set parent collection to a child."
        @collection.errors.add(:base, "Cannot set parent collection to a child.")
        format.html { render action: "edit" }
      elsif update_collection_attrs_suc
        format.html { redirect_to edit_collection_path(@collection), notice: 'Collection was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /collections/1
  # DELETE /collections/1.json
  def destroy
    @collection = Collection.find(params[:id])
    
    #destroy all child documents
    @collection.documents.each do |d|
      upload_remove(d)  #Removes upload record if file is deleted
      d.destroy
    end
    
    #destroy all child collections
    @collection.collections.each do |c|
      collection_recursive_destroy(c)
    end
    
    @collection.destroy

    respond_to do |format|
      format.html { redirect_to collections_url }
      format.json { head :ok }
    end
  end
  
  #Downloads a single "note" file linked to a collection.
  # GET /collections/download_note_collection/1
  def download_note_collection
    collection = Collection.find(params[:id])
    authorize! :download_note_collection, collection
    upload = Upload.find(params[:upload_id])
    
    send_file upload.upfile.path, 
     :filename => upload.upfile_file_name, 
     :type => 'application/octet-stream'
  end
  
  # 
  def validate_collection
    @collection = Collection.find(params[:id])

    suc_valid = validate_collection_helper(@collection)
    
    respond_to do |format|
      if suc_valid
        format.html { redirect_to @collection, notice: 'Collection successfully validated.' }
        format.json { head :ok }
      else
        flash[:error] = 'Collection FAILED to validate.'
        format.html { redirect_to @collection }
        format.json { render json: @collection.errors, status: :unprocessable_entity }
      end
    end
  end
  
  
  # 
  def validate_doc
    @document = Document.find(params[:id])

    job = Job.new(:description => "Document #{@document.name} validation")
    job.save
    job.submit_job(current_user, @document, {:ifilter => nil})

    suc_valid = true

    respond_to do |format|
      if suc_valid
        format.html { redirect_to @document, notice: 'Document successfully validated.' }
        format.json { head :ok }
      else
        flash[:error] = 'Document FAILED to validate.'
        format.html { redirect_to @document }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end
end
