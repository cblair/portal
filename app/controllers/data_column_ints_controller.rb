class DataColumnIntsController < ApplicationController
  # GET /data_column_ints
  # GET /data_column_ints.json
  def index
    @data_column_ints = DataColumnInt.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @data_column_ints }
    end
  end

  # GET /data_column_ints/1
  # GET /data_column_ints/1.json
  def show
    @data_column_int = DataColumnInt.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @data_column_int }
    end
  end

  # GET /data_column_ints/new
  # GET /data_column_ints/new.json
  def new
    @data_column_int = DataColumnInt.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @data_column_int }
    end
  end

  # GET /data_column_ints/1/edit
  def edit
    @data_column_int = DataColumnInt.find(params[:id])
  end

  # POST /data_column_ints
  # POST /data_column_ints.json
  def create
    @data_column_int = DataColumnInt.new(params[:data_column_int])

    respond_to do |format|
      if @data_column_int.save
        format.html { redirect_to @data_column_int, :notice => 'Data column int was successfully created.' }
        format.json { render :json => @data_column_int, :status => :created, :location => @data_column_int }
      else
        format.html { render :action => "new" }
        format.json { render :json => @data_column_int.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /data_column_ints/1
  # PUT /data_column_ints/1.json
  def update
    @data_column_int = DataColumnInt.find(params[:id])

    respond_to do |format|
      if @data_column_int.update_attributes(params[:data_column_int])
        format.html { redirect_to @data_column_int, :notice => 'Data column int was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @data_column_int.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /data_column_ints/1
  # DELETE /data_column_ints/1.json
  def destroy
    @data_column_int = DataColumnInt.find(params[:id])
    @data_column_int.destroy

    respond_to do |format|
      format.html { redirect_to data_column_ints_url }
      format.json { head :ok }
    end
  end
end
