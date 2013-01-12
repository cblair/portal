class CollectionsController < ApplicationController
  include CollectionsHelper
  include DocumentsHelper
  
  before_filter :require_permissions
  
  def require_permissions
    if params.include?("id")
      collection = Collection.find(params[:id])
      
      if not collection_is_viewable(collection)
        flash[:error] = "Collection not found, or you do not have permissions for this action."
        redirect_to collections_path
      end
    end
  end
  
  # GET /collections
  # GET /collections.json
  def index
    #@collections = Collection.all
    
    @root_collections = Collection.where(:collection_id => nil).order('name')

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @collections }
    end
  end

  # GET /collections/1
  # GET /collections/1.json
  def show    
    @collection = Collection.find(params[:id])
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @collection }
    end
  end

  # GET /collections/new
  # GET /collections/new.json
  def new
    @collection = Collection.new

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
    
    #parent collection stuff
    parent_child_violation = false
    if params.include?("collection") and params[:collection].include?("collection_id") and params[:collection]["collection_id"] != ""
      parent_collection = Collection.find(params[:collection]["collection_id"])
      if !collection_is_parent(@collection, parent_collection)
        @collection.collection = parent_collection
      else
        parent_child_violation = true
      end
    end
    
    if params.include?("post") and params[:post].include?("ifilter_id") and params[:post][:ifilter_id] != ""
      f = Ifilter.find(params[:post][:ifilter_id])
      validate_collection_helper(@collection, f)
    end

    respond_to do |format|
      if parent_child_violation 
        flash[:error] =  "Warning: cannot set parent collection to a child."
        format.html { redirect_to @collection }
      elsif @collection.update_attributes(params[:collection])
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
    
    suc_valid = validate_document_helper(@document)
    
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
