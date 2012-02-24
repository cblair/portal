class DataColumnsController < ApplicationController
  helper DataColumnsHelper
  
  # GET /data_columns
  # GET /data_columns.json
  def index
    @data_columns = DataColumn.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @data_columns }
    end
  end

  # GET /data_columns/1
  # GET /data_columns/1.json
  def show
    @data_column = DataColumn.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @data_column }
    end
  end

  # GET /data_columns/new
  # GET /data_columns/new.json
  def new
    @data_column = DataColumn.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @data_column }
    end
  end

  # GET /data_columns/1/edit
  def edit
    @data_column = DataColumn.find(params[:id])
  end

  # POST /data_columns
  # POST /data_columns.json
  def create
    @data_column = DataColumn.new(params[:data_column])

    respond_to do |format|
      if @data_column.save
        format.html { redirect_to @data_column, :notice => 'Data column was successfully created.' }
        format.json { render :json => @data_column, :status => :created, :location => @data_column }
      else
        format.html { render :action => "new" }
        format.json { render :json => @data_column.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /data_columns/1
  # PUT /data_columns/1.json
  def update
    @data_column = DataColumn.find(params[:id])

    respond_to do |format|
      if @data_column.update_attributes(params[:data_column])
        format.html { redirect_to @data_column, :notice => 'Data column was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @data_column.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /data_columns/1
  # DELETE /data_columns/1.json
  def destroy
    @data_column = DataColumn.find(params[:id])
    @data_column.destroy

    respond_to do |format|
      format.html { redirect_to data_columns_url }
      format.json { head :ok }
    end
  end
  
  
  #Gets the DataColumn<type> of arg 'name' for the Data of arg 'id'
  def get_data_column_json
    d_id = params[:id]
    dc_name = params[:name]
    d = Datum.find(d_id)
    dc = d.data_columns.where("name='#{dc_name}' AND datum_id=#{d_id}").first()
    #TODO: different types
    if dc.dtype == "integer"
      @dct = dc.data_column_ints.where(:data_column_id => dc.id)
      #redirect_to "/DataColumnInts/#{dct.id}.json"
      render :json => @dct
    else
      #No type found
      flash[:message]="Warning: could not find type for this data column"
      redirect_to "/Metadata"
    end

  end
end
