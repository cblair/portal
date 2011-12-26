class MetadataController < ApplicationController
  
  # GET /metadata
  # GET /metadata.json
  def index
    @metadata = Metadatum.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @metadata }
    end
  end

  # GET /metadata/1
  # GET /metadata/1.json
  def show
    @metadatum = Metadatum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @metadatum }
    end
  end

  # GET /metadata/new
  # GET /metadata/new.json
  def new
    validates_presence_of :param1 

    @metadatum = Metadatum.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @metadatum }
    end
  end

  # GET /metadata/1/edit
  def edit
    @metadatum = Metadatum.find(params[:id])
  end

  # POST /metadata
  # POST /metadata.json
  def create
    @metadatum = Metadatum.new(params[:metadatum])

    respond_to do |format|
      if @metadatum.save
        format.html { redirect_to @metadatum, :notice => 'Metadatum was successfully created.' }
        format.json { render :json => @metadatum, :status => :created, :location => @metadatum }
      else
        format.html { render :action => "new" }
        format.json { render :json => @metadatum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /metadata/1
  # PUT /metadata/1.json
  def update
    @metadatum = Metadatum.find(params[:id])

    respond_to do |format|
      if @metadatum.update_attributes(params[:metadatum])
        format.html { redirect_to @metadatum, :notice => 'Metadatum was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @metadatum.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /metadata/1
  # DELETE /metadata/1.json
  def destroy
    @metadatum = Metadatum.find(params[:id])
    @metadatum.destroy

    respond_to do |format|
      format.html { redirect_to metadata_url }
      format.json { head :ok }
    end
  end
end
