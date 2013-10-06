class SearchesController < ApplicationController
  include SearchesHelper
  include SearchesDatatableHelper
  #include MergeSearchDatatable
  #include SearchAllDatatable
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
      options =  {
                  :flag => 'f',
                  :from => page,
                  :size => per_page
                }
      start_time = Time.new
      results = ElasticsearchHelper::es_search_dispatcher("es_query_string_search", search, options)
      run_time_seconds = Time.new - start_time
      puts "INFO: Elasticsearch query completed in #{run_time_seconds.inspect} seconds."

      doc_list = get_docs_from_raw_es_data(results, current_user)

      #Don't let unvalidated docs screw up the search results
      validated_doc_list = doc_list.reject {|doc| !doc.validated }
      if !validated_doc_list.empty?
        colnames = get_colnames_in_common(validated_doc_list)
      end
    end

    #
    colnames_in_common_and_merge_search = (!colnames.empty?) && (merge_search)
    if !colnames_in_common_and_merge_search
      colnames = ["Documents", "More Information"]
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
      if merge_search
        format.json { render json: MergeSearchDatatable.new(view_context, current_user)}
      else
        format.json { render json: SearchAllDatatable.new(view_context, current_user)}
      end
    end
  end

  def save_doc_from_search
    @document = Document.new(:name => "Document from Merged Search")
    doc_data = []

    @current_user = current_user

    search = params[:searchval]
    
    #TODO: do one search instead of two

    #Get doc list, so we can get colnames in common
    options =   {
                  #set the ES from (search offset) field from our page method
                  :from => page,
                  #set the ES size (how many from search offset) field from our
                  # per_page method
                  :size => per_page
                }

    options[:flag] = 'm'
    results = ElasticsearchHelper::es_search_dispatcher("es_query_string_search", search, options)

    doc_list = get_docs_from_raw_es_data(results, @current_user)
    colnames = []

    #Don't let unvalidated docs screw up the search results
    validated_doc_list = doc_list.reject {|doc| !doc.validated }
    if !validated_doc_list.empty?
      colnames = get_colnames_in_common(validated_doc_list)
    end

    #Get data results
    options[:flag] = 'f'
    raw_data = ElasticsearchHelper::es_search_dispatcher("es_query_string_search", search, options)

    raw_data.collect do |row|
      doc_name = row["_source"]["_id"]
      score = row["_score"]
      doc_id = doc_name.sub("Document-", "").to_i

      begin
        doc = Document.find(doc_id)
      rescue ActiveRecord::RecordNotFound
        log_and_print "WARN: Document with id #{doc_id} not found in search. Skipping."
        #better decrement our document_count for the results
        next
      end

      doc_data = row["_source"]["data"].collect

    end #end raw_data.collect

    c = Collection.find_or_create_by_name(:name => "From Merged Search")
    c.user_id = current_user.id
    c.save
    @document.collection = c
    @document.stuffing_data = doc_data
    @document.user_id = current_user.id

    respond_to do |format|
      if @document.save
        format.html { redirect_to @document, notice: 'Document from Merged Search was successfully saved.' }
      else
        format.html { render controller: "documents", action: "new" }
      end
    end
  end
end
