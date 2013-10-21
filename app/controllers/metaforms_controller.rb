include MetaformsHelper

class MetaformsController < ApplicationController
  
  before_filter :authenticate_user!
  #load_and_authorize_resource
  #TODO: CanCan permissions
  
  # GET /metaforms/mdf_input/1
  def mdf_input
    @metaform = Metaform.find(params[:metaf][:id])
    @document = Document.find(params[:doc_id])
  end

  # POST /metaforms/mdf_save/1
  def mdf_save
    @metaform = Metaform.find(params[:metaf])
    mf_data = params[:metaform][:metarows_attributes] #passed row data
    document = Document.find(params[:id]) #id is from document
    mdf_saved = metarows_save(mf_data, document)
    
    respond_to do |format|
      if (mdf_saved == true)
        format.html { redirect_to document, notice: 'Metadata was successfully saved.' }
        format.json { head :no_content }
      else
        #format.html { render action: "mdf_input" }
        format.html { redirect_to document, notice: 'ERROR: Metadata was not saved.' }
        format.json { render json: @metaform.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /metaforms
  # GET /metaforms.json
  def index
    @metaforms = Metaform.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @metaforms }
    end
  end

  # GET /metaforms/1
  # GET /metaforms/1.json
  def show
    @metaform = Metaform.find(params[:id])

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
    #puts "new *********************************************************"
    #@metaform.metarows.each do |mr|
    #  p mr
    #end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @metaform }
    end
  end

  # GET /metaforms/1/edit
  def edit
    @metaform = Metaform.find(params[:id])
    #puts "edit ********************************************************"
    #@metaform.metarows.each do |mr|
    #  p mr
    #end
  end

  # POST /metaforms
  # POST /metaforms.json
  def create
    @metaform = Metaform.new(params[:metaform])
    @metaform.user_id = current_user.id
    #puts "create ******************************************************"
    #@metaform.metarows.each do |mr|
    #  p mr
    #end

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
    #puts "update ******************************************************"
    #tmp = params[:_destroy]
    #p "tmp ***", tmp
    #@metaform.metarows.each do |mr|
    #  p mr
    #end

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