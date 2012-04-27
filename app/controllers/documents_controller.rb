class DocumentsController < ApplicationController
  include DocumentsHelper
  include VizHelper
  helper_method :sort_column, :sort_direction
    
  before_filter :autologin_if_dev
  before_filter :authenticate_user!
  
  
  # GET /documents
  # GET /documents.json
  def index
    #Search for data if search comes in
    if params[:search] != nil
      #start recording run time
      stime = Time.now() #start time
      #Delete any temp search docs so we don't search them too 
      Document.destroy_all(:name => ENV['temp_search_doc'])
     
      d = document_search_data_couch(params[:search], params.has_key?("lucky_search"))
      c=Collection.find_or_create_by_name("Recent Searches")
      c.save
      
      @temp_search_document = Document.new
      @temp_search_document.name = ENV['temp_search_doc']
      @temp_search_document.collection = c
      @temp_search_document.stuffing_data = d
      @temp_search_document.stuffing_is_search_doc = TRUE
      @temp_search_document.save
      
      etime = Time.now() #end time
      ttime = etime - stime #total time
    
      @documents = Document.search(params[:search]).order(sort_column + " " + sort_direction).paginate(:per_page => 5, :page => params[:page])

      flash[:notice]="Searched data in #{ttime} seconds."
    else
        @documents = Document.all.paginate(:per_page => 5, :page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @documents }
    end
  end

  # GET /documents/1
  # GET /documents/1.json
  def show
    @document = Document.find(params[:id])
    chart = Chart.find_by_document_id(@document)
    @chart = chart || Chart.find(newchart({:document_id => @document}))
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @document }
    end
  end
  # GET /documents/new
  # GET /documents/new.json
  def new
    @document = Document.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @document }
    end
  end

  # GET /documents/1/edit
  def edit
    @document = Document.find(params[:id])
  end

  # POST /documents
  # POST /documents.json
  def create
    debugger
    @document = Document.new(params[:document])

    respond_to do |format|
      if @document.save
        format.html { redirect_to @document, notice: 'Document was successfully created.' }
        format.json { render json: @document, status: :created, location: @document }
      else
        format.html { render action: "new" }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /documents/1
  # PUT /documents/1.json
  def update
    @document = Document.find(params[:id])

    respond_to do |format|
      if @document.update_attributes(params[:document])
        format.html { redirect_to @document, notice: 'Document was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /documents/1
  # DELETE /documents/1.json
  def destroy
    @document = Document.find(params[:id])
    @document.destroy

    respond_to do |format|
      format.html { redirect_to documents_url }
      format.json { head :ok }
    end
  end
  
  #Creates new doc data based on some predefined methods
  def manip
    d = Document.find(params[:id])
    colname = params[:manip_colname]
    @document = Document.create(
                                :name => "#{d.name}_manip", 
                                :collection => d.collection,
                                :stuffing_data => get_data_map(d, colname))
                                
    render "show"
  end

  def download
      redirect_to csv_export_path(params[:id], :format => :csv)
  end
  
  
  def search_test
    d = document_search_data_couch("test")

    @temp_search_document = Document.find_or_create_by_name(ENV['temp_search_doc'])
    #TODO: set to internal (user?) collection
    #@temp_search_document.collection = c
    @temp_search_document.stuffing_data = d
    @temp_search_document.save
    
    @documents = Document.search(params[:search]).order(sort_column + " " + sort_direction).paginate(:per_page => 5, :page => params[:page])
    
    render "index"
  end
  
  def sort_column
    Document.column_names.include?(params[:sort]) ? params[:sort] : "name"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end
end
