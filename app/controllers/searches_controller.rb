class SearchesController < ApplicationController
  include SearchesHelper
  include SearchesDatatableHelper
  #include MergeSearchDatatable
  #include SearchAllDatatable
  include ElasticsearchHelper

  delegate :link_to, to: :view_context

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
    doc_results = []
    viewable_doc_list = []
    unviewable_doc_list = []
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

      doc_results = get_viewable_and_nonviewable_docs_from_raw_es_data(results, current_user)
      viewable_doc_list = doc_results[:viewable_docs]
      unviewable_doc_list = doc_results[:unviewable_docs]

      #Don't let unvalidated docs screw up the search results
      validated_doc_list = viewable_doc_list.reject {|doc| !doc.validated }
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
      "documents" => viewable_doc_list.collect {|doc| doc.name}, 
      "colnames" => colnames,
      "doc_links" => viewable_doc_list.collect {|doc| view_context.link_to(doc.name, doc)},
      #Show some unviewable doc links, but only the first 10 in case there's a lot.
      "unviewable_doc_links" => unviewable_doc_list[0..10].collect {|doc| view_context.mail_to doc.user.email, "#{doc.name} - request access via email.", subject: "Requesting access to #{doc.name}"}
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
    @document.user = current_user
    
    c = Collection.find_or_create_by_name(:name => "From Merged Search")
    @document.collection = c
    doc_data = []

    search = params[:searchval]
    
    @document.create_merge_search_document(search, @current_user)

    respond_to do |format|
      if @document.save
        format.html { redirect_to @document, notice: 'Document from Merged Search was successfully saved.' }
      else
        format.html { render controller: "documents", action: "new" }
      end
    end
  end

  def save_doc_from_merge_search
    @document = Document.new(:name => "Document from Merged Search")
    @document.user = current_user
    
    c = Collection.find_or_create_by_name(:name => "From Merged Search")
    @document.collection = c

    search = params[:searchval]

    #@document.create_merge_search_document(search, view_context, current_user)
    job = Job.new(:description => "#{@document.name} (document) merge")   

    respond_to do |format|
      if @document.save && job.save
        #Submit the job.
        job.submit_job(current_user, @document, 
          {:mode => :merge_search, :params => params, :params => params}) 

        #Point the document to the job.
        @document.job = job
        @document.save

        format.json { render json: \
          {\
            "document_link" => link_to(@document.name, @document),\
            "job_link" => link_to(job.description, job)\
          }\
        }
      else
        format.json { render json: @search.errors, status: :unprocessable_entity }
      end
    end
  end
end
