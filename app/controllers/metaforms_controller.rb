#include MetaformsHelper

class MetaformsController < ApplicationController
  include MetaformsHelper
  require 'will_paginate/array'
  
  before_filter :authenticate_user!
  load_and_authorize_resource
  
  # GET /metaforms/1/mdf_copy
  def mdf_copy
    @metaform = Metaform.find(params[:mf_id]) #params[:id] causes cancan to block access

    metaform_new = Metaform.new
    metaform_new.update_attributes( @metaform.attributes ) #generates warning (bad?)
    metaform_new.update_attribute(:user_id, current_user.id) #all users can copy a metaform
    mf_name = metaform_new.name
    metaform_new.update_attribute(:name, mf_name + " (copy)")
  
    copy_success = metarows_copy(metaform_new) #copies each row of metadata in a metaform

    respond_to do |format|
      #if @metaform.update_attributes(params[:metaform])
      if copy_success == true
        format.html { redirect_to metaforms_path, notice: 'Metaform was successfully copied.' }
        format.json { head :no_content }
      else
        format.html { render action: "show" }
        format.json { render json: @metaform.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /metaforms/mdf_input
  def mdf_input
    @document = Document.find(params[:doc_id])
    authorize! :add_md, @document if params[:doc_id] #custom action, CanCan
    
    if (params[:metaf][:id].blank?)
      redirect_to @document, notice: 'Not a Metaform.'
    else
      @metaform = Metaform.find(params[:metaf][:id])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @metaforms }
    end
  end

  # POST /metaforms/mdf_save
  def mdf_save
    @document = Document.find(params[:doc_id])
    authorize! :add_md, @document if params[:metaf] #custom action, CanCan
    @metaform = Metaform.find(params[:metaf])
    
    mdf_saved = false
    if (params[:metaform] == nil)
      mdf_saved = false
    else
      mf_data = params[:metaform][:metarows_attributes] #passed row data
      mdf_saved = metarows_save(mf_data, @document)
    end
    
    respond_to do |format|
      if (mdf_saved == true)
        format.html { redirect_to @document, notice: 'Metadata was successfully saved.' }
        format.json { render json: @document, status: :created, location: document  }
      else
        format.html { redirect_to @document, notice: 'ERROR: Metadata was not saved.' }
        format.json { render json: @metaform.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /metaforms
  # GET /metaforms.json
  def index
    #@metaforms = Metaform.all
    @metaforms = Metaform.where("user_id = ?", current_user).paginate(:page => params[:page], :per_page => 10)
    @metaforms_other = Metaform.where("user_id != ?", current_user).paginate(:page => params[:page], :per_page => 10)

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @metaforms }
    end
  end

  # POST /metaforms/mdf_sort
  def mdf_sort
    metarows = params[:metarow]
    
    metarows.each_with_index do |id, idx|
      Metarow.update_all( {index: idx}, {:id => id} )
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.js { render js: "metarow update success"}
    end
  end

  # GET /metaforms/1
  # GET /metaforms/1.json
  def show
    @metaform = Metaform.find(params[:id])
    @owner = User.find(@metaform.user_id).email  #gets email/ID of project owner
    check_index()  #Makes sure metadata rows have an index, sets if missing
    
    @metaform.metarows.sort_by! {|row| row.index}  #sort metarows by index
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @metaform }
    end
  end

  # GET /metaforms/new
  # GET /metaforms/new.json
  def new
    @metaform = Metaform.new
    setup_mrows()

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @metaform }
    end
  end

  # GET /metaforms/1/edit
  def edit
    @metaform = Metaform.find(params[:id])
  end

  # POST /metaforms
  # POST /metaforms.json
  def create
    @metaform = Metaform.new(params[:metaform])
    @metaform.user_id = current_user.id

    respond_to do |format|
      if @metaform.save
        format.html { redirect_to @metaform, notice: 'Metaform was successfully created.' }
        format.json { render json: @metaform, status: :created, location: @metaform }
      else
        format.html { render action: "new" }
        format.json { render json: @metaform.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /metaforms/1
  # PUT /metaforms/1.json
  def update
    @metaform = Metaform.find(params[:id])
    #param_new = sort_metarows(params[:metaform][:metarows_attributes])
    #params[:metaform][:metarows_attributes] = param_new

    respond_to do |format|
      if @metaform.update_attributes(params[:metaform])
        format.html { redirect_to @metaform, notice: 'Metaform was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @metaform.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /metaforms/1
  # DELETE /metaforms/1.json
  def destroy
    @metaform = Metaform.find(params[:id])
    @metaform.destroy

    respond_to do |format|
      format.html { redirect_to metaforms_url }
      format.json { head :no_content }
    end
  end
end
