class ProjectsController < ApplicationController
  include ProjectsHelper
  
  before_filter :authenticate_user!

  # GET /projects
  # GET /projects.json
  def index
    @projects = Project.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @projects }
    end
  end

  # GET /projects/1
  # GET /projects/1.json
  def show
    @project = Project.find(params[:id])

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
  end
  
  # GET /projects/groups/1
  def groups
    @project = Project.find(params[:id])
    #puts("p = #{@project.name}") #debug (WORKS)
    u = User.all #get a list of users (for changing owner)
    
    u.each do |x|
      #puts ("user = #{x.email}")  #debug (WORKS)
    end
    
  end
  
  # PUT /projects/add_menu/1
  # PUT /projects/add_menu/1.json
  def add_menu
    #NOT USED:
    @project = Project.find(params[:id])

    respond_to do |format|
      format.html # add.html.erb
      format.json { render json: @project }
    end
  end
  
  # PUT /projects/add/1
  # PUT /projects/add/1.json
  def add 
    #NOT USED:
    #@project = Project.find(params[:id])

    respond_to do |format|
      format.html # add.html.erb
      format.json { render json: @project }
    end
  end
  
  # PUT /projects/owner/1
  # PUT /projects/owner/1.json
  def owner
    @project = Project.find(params[:proj_id])
		#puts("*** project = #{@project.name}, id #{@project.id}")
		#puts("*** currentuser = #{current_user.id}.") #debug
	
	if (params.include?("proj_id") and params[:proj_id] != "" and @project != nil)
	  change_owner (@project) #calls project helper
    end
    
    respond_to do |format|
      if (@user_id_err == true) #see helper
        format.html { redirect_to groups_path(@project), notice: 'Not an email, please try again.'}
        # TODO: format JSON?
      else
        format.html { redirect_to projects_path, notice: 'Project ownership successfully changed.' }
        format.json { head :ok }
      end
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
  
  # POST /projects
  # POST /projects.json
  def create
    @project = Project.new(params[:project])
    @project.user = current_user

    respond_to do |format|
      if @project.save
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
    #@project = Project.find(params[:project_id])
    @project = Project.find(params[:id])

    respond_to do |format|
      if @project.update_attributes(params[:project])
        format.html { redirect_to @project, notice: 'Project was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @project.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.json
  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to projects_url }
      format.json { head :ok }
    end
  end
end
