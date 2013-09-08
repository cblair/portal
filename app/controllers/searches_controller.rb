
class SearchesController < ApplicationController
  include SearchesHelper
  include ElasticsearchHelper

  delegate :link_to, to: :@view

  # GET /searches
  # GET /searches.json
  def index
    @searches = Search.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @searches }
    end
  end

  # GET /searches/1
  # GET /searches/1.json
  def show
    @search = Search.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @search }
    end
  end

  # GET /searches/new
  # GET /searches/new.json
  def new
    @search = Search.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @search }
    end
  end

  # GET /searches/1/edit
  def edit
    @search = Search.find(params[:id])
  end

  # POST /searches
  # POST /searches.json
  def create
    @search = Search.new(params[:search])

    respond_to do |format|
      if @search.save
        format.html { redirect_to @search, notice: 'Search was successfully created.' }
        format.json { render json: @search, status: :created, location: @search }
      else
        format.html { render action: "new" }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /searches/1
  # PUT /searches/1.json
  def update
    @search = Search.find(params[:id])

    respond_to do |format|
      if @search.update_attributes(params[:search])
        format.html { redirect_to @search, notice: 'Search was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /searches/1
  # DELETE /searches/1.json
  def destroy
    @search = Search.find(params[:id])
    @search.destroy

    respond_to do |format|
      format.html { redirect_to searches_url }
      format.json { head :no_content }
    end
  end

  #Does an initial search, and returns the common columns names for all matching documents
  def search_init
    search = ""
    doc_list = []
    colnames = []
    result_rows = []

    if params.include?("searchval")
      search = params["searchval"]
    end
    
    if search != ""
      results = es_query_string_search(search, 'm')

      doc_list = get_docs_from_raw_es_data(results, current_user)

      #Don't let unvalidated docs screw up the search results
      validated_doc_list = doc_list.reject {|doc| !doc.validated }
      if !validated_doc_list.empty?
        colnames = get_colnames_in_common(validated_doc_list)
      end
    end

    #if colnames is empty, then just have one columns named "Documents"
    if colnames.empty?
      colnames = ["Documents"]
    end

    search_data = {
      "documents" => doc_list.collect {|doc| doc.name}, 
      "colnames" => colnames,
      "doc_links" => doc_list.collect {|doc| view_context.link_to(doc.name, doc)}
    }

    respond_to do |format|
      #  format.html # index.html.erb
      #  format.json { render json: @documents }
      #TODO
      format.json { render json: search_data }
    end
  end

  #Searches all documents and get back only the columns in common
  def search_all
    respond_to do |format|
      #  format.html # index.html.erb
      #  format.json { render json: @documents }
      format.json { render json: SearchAllDatatable.new(view_context, current_user)}
    end
  end
end
