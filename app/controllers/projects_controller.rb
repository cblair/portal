class ProjectsController < ApplicationController
  include ProjectsHelper
  #require 'will_paginate/array'
  
  before_filter :authenticate_user!
  load_and_authorize_resource

  # GET /projects
  # GET /projects.json
  def index
    #@projects = Project.order("name").all.paginate(:per_page => 5, :page => params[:page])
    @projects = Project.order("name").all
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @projects }
    end
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @project = Project.find(params[:id])
      #gets all docs for the project
    @proj_docs = Document.where("project_id = ?", @project.id).order("name")
    @owner = User.find(@project.user_id).email #gets email/ID of project owner
    
    @public = ""
    if (@project.public == true)
      @public = "Yes"
    elsif (@project.public == false)
      @public = "No"
    else
      @public = ""
    end

    @root_collections = []
    project_collections_ids = []
    @project.collections.each do |collection|
      if collection.ancestors.empty?
        @root_collections << collection
        next
      end
      if !collection.ancestors.collect {|c| c.projects.include?(@project)}.all?
        @root_collections << collection
      end
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @project }
    end
  end

  # GET /projects/new
  # GET /projects/new.json
  def new
    @project = Project.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @project }
    end
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
    
    #call to project helper (for removing collaborators)
    @colab_list = colab_list_get()
    @editor_list = editor_list_get()
  end
  
  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(params[:project])
    @project.user_id = current_user.id
    @project.public = false
    user = User.where(:id => params[:new_user_id]).first #for adding a collaborator
    
    respond_to do |format|
      if @project.save
        colab_add(user)
        format.html { redirect_to @project, notice: 'Project was successfully created.' }
        format.json { render json: @project, status: :created, location: @project }
      else
        format.html { render action: "new" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.json
  def update
    @project = Project.find(params[:id])    
    user = User.where(:id => params[:new_user_id]).first #collaborator
    colab_user_ids = params[:colab_user_ids] #removing collaborators
    editor_new = User.where(:id => params[:new_editor_id]).first #editor
    editor_user_ids = params[:editor_user_ids] #removing editors

    if (@project != nil and user != nil)
      colab_add(user) #Adds a new collaborator
    end
    
    if (@project != nil and editor_new != nil)
      editor_add(editor_new) #Adds a new editor
    end
    
    if (@project != nil and colab_user_ids != nil and not colab_user_ids.blank?)
      colab_remove_project(colab_user_ids) #removes collaborators from a project
      colabs_remove_docs(editor_user_ids) #removes collaborators from documents
    end
    
    if (@project != nil and editor_user_ids != nil and not editor_user_ids.blank?)
      editor_remove_project(editor_user_ids) #removes collaborators from a project
    end

    #TODO: add new error message, use different error flag?
    respond_to do |format|
      if @project.update_attributes(params[:project])
        #TODO: add message if selected user is blank?
        format.html { redirect_to edit_project_path(@project), notice: 'Project was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end
  
  # PUT /projects/1
  # PUT /projects/1.json
  def project_public_set
    project = Project.find(params[:id]) #needed for "respond_to"
    
    if (params.include?(:id) and project != nil)
      is_public = proj_public_set(project)
    end
    
    respond_to do |format|
      if (is_public == true)
        format.html { redirect_to project, notice: 'Project is now public.'}
        format.json { head :ok }
      elsif (is_public == false)
        format.html { redirect_to project, notice: 'Project is now private.'}
        format.json { head :ok }
      else
        format.html { redirect_to project, notice: 'ERROR: access control unknown.'}
        format.json { head :ok }
      end
    end
  end

  # PUT /projects/add_project_collection/1
  # PUT /projects/add_project_collection/1.json
  def add_project_collection
    project = Project.find(params[:project_id]) #needed for "respond_to"
    collection_id = params[:collection][:collection_id]
    
    if (params.include?(:project_id) and project != nil and collection_id != nil and not collection_id.blank?)
      add_collection(project, collection_id) #adds a collection to a project
    else
      add_col_err = true
    end
    
    respond_to do |format|
      if (add_col_err == true)
        format.html { redirect_to project, notice: 'Error adding collection.'}
        # TODO: format JSON?
      else
        format.html { redirect_to project, notice: 'Collection added successfully.' }
        format.json { head :ok }
      end
    end
  end
  
  # PUT /projects/remove_project_collections/1
  # PUT /projects/remove_project_collections/1.json
  def remove_project_collections
    project = Project.find(params[:project_id]) #needed for "respond_to"
    col_checked = params[:col_ids] #list of collection ids to be removed
    
    if (params.include?(:project_id) and project != nil and not col_checked.blank?)
      remove_collection_checked(project, col_checked)
    else
      @remove_col_err = true
    end
    
    #TODO: different error messages for error and nothting selected?
    respond_to do |format|
      if (@remove_col_err == true)
        format.html { redirect_to project, notice: 'Error, please try again.'}
        # TODO: format JSON?
      else
        format.html { redirect_to project, notice: 'Project updated successfully.' }
        format.json { head :ok }
      end
    end
  end
  
  # PUT /projects/add_project_doc
  # PUT /projects/add_project_doc
  def add_project_doc
    project = Project.find(params[:project_id]) #needed for "respond_to"
    doc_id = params[:document][:document_id]
    
    #TODO: More error checking?
    if (params.include?(:project_id) and not params[:project_id].blank? and project != nil)
      add_doc(project, doc_id)
    else
      @add_doc_err = true
    end
     
    respond_to do |format|
      if (@add_doc_err == true)
        format.html { redirect_to project, notice: 'Error adding document.'}
        # TODO: format JSON?
      else
        format.html { redirect_to project, notice: 'Document added successfully.' }
        format.json { head :ok }
      end
    end
  end
  
  # PUT /projects/remove_project_doc
  # PUT /projects/remove_project_doc
  def remove_project_docs
    project = Project.find(params[:project_id]) #needed for "respond_to"
    docs_checked = params[:doc_ids] #list of document ids to be removed
    
    if (params.include?(:project_id) and project != nil and not docs_checked.blank?)
      remove_docs_checked(project, docs_checked)
    else
      @remove_doc_err = true
    end

    #TODO: different error messages for error and nothting selected?
    respond_to do |format|
      if (@remove_doc_err == true)
        format.html { redirect_to project, notice: 'Error, please try again.'}
        # TODO: format JSON?
      else
        format.html { redirect_to project, notice: 'Project updated successfully.' }
        format.json { head :ok }
      end
    end
  end
  
  # PUT /projects/owner/1
  # PUT /projects/owner/1.json
  def owner
    @project = Project.find(params[:id])
    #target_user_id = params[:user_id][:id]
    target_user_id = params[:user][:user_id]

    if (params.include?(:id) and params[:id] != "" and @project != nil)
      if (not target_user_id.blank? and target_user_id != nil)
        change_owner(target_user_id) #calls project helper
      else
        @user_id_err = true
      end
    else
      @user_id_err = true
    end
    
    respond_to do |format|
      if (@user_id_err == true) #see helper
        format.html { redirect_to edit_project_path(project), notice: 'Not an email, please try again.'}
        # TODO: format JSON?
      else
        format.html { redirect_to projects_path, notice: 'Project ownership successfully changed.' }
        format.json { head :ok }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project = Project.find(params[:id])
    project_clean() #needs @project
    @project.destroy

    respond_to do |format|
      format.html { redirect_to projects_url }
      format.json { head :ok }
    end
  end

  # GET /projects/owner/1
  def owner_OLD
  # this version of owner uses an input text field
=begin
    # finds the project with the matching passed id
    @project = Project.find(params[:proj_id])
	# returns an array of users that match the given email
    @user_list = User.where("email = ?", params[:user_email])
    
    respond_to do |format|
	  if (@user_list.length == 0)
	    format.html { redirect_to groups_path(@project), notice: 'Email not found, please try again.'}
	    # *** this code needs to be changed? ***
	    format.json { render json: @project.errors, status: :unprocessable_entity }
	  else
	    # assuming first user found is the correct user
	    @target_user = @user_list[0]
	    # gets an array of documents with the given project ID
        @docs = Document.where("project_id = ?", @project.id)
	    # changes user ID of documents to target user    
        @docs.each do |d|
          d.update_attributes(:user_id => @target_user.id)
        end
        # TODO: collections code here?
        # changes current project's user ID to target user's ID    	    
	    if @project.update_attributes(:user_id => @target_user.id)
          format.html { redirect_to projects_path, notice: 'Project ownership successfully changed.' }
          format.json { head :ok }
        else
          # *** this code needs to be changed? ***
          format.html { render action: "edit" }
          format.json { render json: @project.errors, status: :unprocessable_entity }
        end
	  end
    end
=end
  end
end
