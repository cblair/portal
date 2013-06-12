class CollectionsController < ApplicationController
  include CollectionsHelper
  include DocumentsHelper

  require 'will_paginate'
  
  #before_filter :authenticate_user!
  before_filter :require_permissions
  
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
  end

  # POST /collections
  # POST /collections.json
  def create
    @collection = Collection.new(params[:collection])
    @collection.user = current_user

    respond_to do |format|
      if @collection.save
        format.html { redirect_to @collection, notice: 'Collection was successfully created.' }
        format.json { render json: @collection, status: :created, location: @collection }
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
    if params.include?("collection") and params[:collection].include?("parent_id") and params[:collection]["parent_id"] != ""
      parent_collection = Collection.find(params[:collection]["parent_id"])

      #if !collection_is_parent(@collection, parent_collection)
      if !parent_collection.ancestors.include?(@collection)
        @collection.parent_id = parent_collection.id
      else
        parent_child_violation = true
      end
    end
    
    #Update
    #do this now, so the spawn doesn't PG:Error b/c spawned code has locked @colllection
    update_collection_attrs_suc = false
    if not parent_child_violation
      update_collection_attrs_suc = @collection.update_attributes(params[:collection])
    end

    #Validation
    if params.include?("post") and params[:post].include?("ifilter_id") and params[:post][:ifilter_id] != ""
      f = get_ifilter(params[:post][:ifilter_id].to_i)

      validate_collection_helper(@collection, f)
    end

    Job.where(:waiting => true).each do |job|
      job.submit_job({:ifilter => f})
    end

    respond_to do |format|
      if parent_child_violation 
        #flash[:error] =  "Warning: cannot set parent collection to a child."
        @collection.errors.add(:base, "Cannot set parent collection to a child.")
        format.html { render action: "edit" }
      elsif update_collection_attrs_suc
        format.html { redirect_to @collection, notice: 'Collection was successfully updated.' }
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
    job.user = current_user
    job.save
    job.submit_job(@document, {:ifilter => nil})

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
  
  
  def pub_priv_collection
    @collection = Collection.find(params[:id])
    
    if params.include?("public")
      if params[:public] == "true"
        public = true
      else
        public = false
      end
      
      set_pub_priv_collection_helper(@collection, public)
    end

    respond_to do |format|
      if @collection.save
        format.html { redirect_to @collection, notice: 'Collection permissions were successfully changed.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end
end
