class IfiltersController < ApplicationController
  before_filter :autologin_if_dev
  before_filter :authenticate_user!
  
  include IfiltersHelper
  
  # GET /ifilters
  # GET /ifilters.json
  def index
    @ifilters = Ifilter.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @ifilters }
    end
  end

  # GET /ifilters/1
  # GET /ifilters/1.json
  def show
    @ifilter = Ifilter.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @ifilter }
    end
  end

  # GET /ifilters/new
  # GET /ifilters/new.json
  def new
    @ifilter = Ifilter.new
    
    @ifilter_headers = get_ifilter_headers(@ifilter)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @ifilter }
    end
  end

  # GET /ifilters/1/edit
  def edit
    @ifilter = Ifilter.find(params[:id])
    @ifilter_headers = get_ifilter_headers(@ifilter)
  end

  # POST /ifilters
  # POST /ifilters.json
  def create
    @ifilter = Ifilter.create(params[:ifilter])
    
    #get header filters
    if params.include?('ifilter_headers')
      @ifilter.stuffing_filter_headers = params[:ifilter_headers]
    end
    
    
    @ifilter.stuffing_headers = []
    if params.include?('ifilter_headers')
      params[:ifilter_headers].each do |header|
        @ifilter.stuffing_headers <<  {
                                        :id => header[0],
                                        :val => header[1]
                                      }
      end
    end

    respond_to do |format|
      if @ifilter.save
        format.html { redirect_to @ifilter, notice: 'Ifilter was successfully created.' }
        format.json { render json: @ifilter, status: :created, location: @ifilter }
      else
        format.html { render action: "new" }
        format.json { render json: @ifilter.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /ifilters/1
  # PUT /ifilters/1.json
  def update
    @ifilter = Ifilter.find(params[:id])

    @ifilter.stuffing_headers = []
    if params.include?('ifilter_headers')
      params[:ifilter_headers].each do |header|
        @ifilter.stuffing_headers <<  {
                                        :id => header[0],
                                        :val => header[1]
                                      }
      end
    end

    respond_to do |format|
      if @ifilter.update_attributes(params[:ifilter])
        format.html { redirect_to @ifilter, notice: 'Ifilter was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @ifilter.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ifilters/1
  # DELETE /ifilters/1.json
  def destroy
    @ifilter = Ifilter.find(params[:id])
    @ifilter.destroy

    respond_to do |format|
      format.html { redirect_to ifilters_url }
      format.json { head :ok }
    end
  end
end
