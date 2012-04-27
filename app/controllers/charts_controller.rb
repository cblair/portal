class ChartsController < ApplicationController
    include DocumentsHelper
  # GET /charts
  # GET /charts.json
  def index
    @charts = Chart.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @charts }
    end
  end

  # GET /chart/:id/:last_id
  def showjson
    @chart = Chart.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: get_last_n_above_id(@chart.document_id,
                                                     @chart.x_column,
                                                     @chart.y_column,
                                                     params[:last_id],
                                                     @chart.numdraw)}
    end
  end


  # GET /charts/new
  # GET /charts/new.json
  def new
    @chart = Chart.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @chart }
    end
  end

  # GET /charts/1/edit
  def edit
    @chart = Chart.find(params[:id])
  end

  # POST /charts
  # POST /charts.json
  def create
    @chart = Chart.new(params[:chart])

    respond_to do |format|
      if @chart.save
        format.html { redirect_to @chart, notice: 'Chart was successfully created.' }
        format.json { render json: @chart, status: :created, location: @chart }
      else
        format.html { render action: "new" }
        format.json { render json: @chart.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /charts/1
  # PUT /charts/1.json
  def update
    @chart = Chart.find(params[:id])

    respond_to do |format|
      if @chart.update_attributes(params[:chart])
        format.html { redirect_to @chart, notice: 'Chart was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @chart.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /charts/1
  # DELETE /charts/1.json
  def destroy
    @chart = Chart.find(params[:id])
    @chart.destroy
    puts 'GOT DESTROY'

    respond_to do |format|
      format.html { redirect_to visualizations_url, notice: 'Chart deleted' }
      format.json { head :ok }
    end
  end
end
