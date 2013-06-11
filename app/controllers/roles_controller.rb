class RolesController < ApplicationController
  include RolesHelper

  before_filter :authenticate_user!
  load_and_authorize_resource :except => :edit_each_user_role
  
  # GET /roles
  # GET /roles.json
  def index
    @roles = Role.order("name").all
    @user_list = User.order("email").all
    
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @roles }
    end
  end

  # GET /roles/1
  # GET /roles/1.json
  def show
    @role = Role.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @role }
    end
  end

  # GET /roles/new
  # GET /roles/new.json
  def new
    @role = Role.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @role }
    end
  end

  # GET /roles/1/edit
  def edit
    @role = Role.find(params[:id])
  end

  # POST /roles
  # POST /roles.json
  def create
    @role = Role.new(params[:role])

    respond_to do |format|
      if @role.save
        format.html { redirect_to @role, notice: 'Role was successfully created.' }
        format.json { render json: @role, status: :created, location: @role }
      else
        format.html { render action: "new" }
        format.json { render json: @role.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /roles/1
  # PUT /roles/1.json
  def update
    @role = Role.find(params[:id])
    
    respond_to do |format|
      if @role.update_attributes(params[:role])
        format.html { redirect_to @role, notice: 'Role was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @role.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit_each_user_role
    @user = User.find(params[:id])
    @roles = Role.all
    #needed for cancan, avoids database query bug by cancan that passes role id instead of user id
    authorize! :manage, @user
  end
  
  def update_each_user_role
    @user = User.find(params[:id])
    
    @roles = []
    if params[:user].nil?
      #special case: all checkboxes unchecked
    else
      #edit_each_user_role only returns an array of role ids, to update user.roles
      #we need to find each role object (not just id)
      params[:user][:role_ids].each do |role_id|
        @roles << Role.find(role_id)
      end
    end
    
    #TODO: change roles to pass ids (not objects)?
    update_user_roles(@roles, @user)
    @update_success = true

    @update_success = true    
    respond_to do |format|
      if (@update_success)
        format.html { redirect_to roles_path, notice: 'User roles was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { redirect_to edit_each_role_path(@user), notice: 'Error updateing roles.' }
        format.json { head :no_content }
      end
    end
  end

  # DELETE /roles/1
  # DELETE /roles/1.json
  def destroy
    @role = Role.find(params[:id])
    @role.destroy

    respond_to do |format|
      format.html { redirect_to roles_url }
      format.json { head :no_content }
    end
  end
end
