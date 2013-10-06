class MergeSearchDatatable
  include SearchesHelper
  include SearchesDatatableHelper
  include ElasticsearchHelper
  require 'will_paginate/array'

  delegate :params, :h, :link_to, :document_path, to: :@view


  def initialize(view, current_user)
    @view = view
    @current_user = current_user
  end

  def as_json(options = {})
    #Get our search data now, so we set all the search side affects
    # now (i.e. counts, modes, etc.)
    aaData = data

    {
      sEcho:params[:sEcho].to_i,
      iTotalRecords: search_data.count,
      iTotalDisplayRecords: search_data.count,
      aaData:
        #Format:
        #  [
        #    ["test","",nil],
        #    ["test","",nil]
        #  ]
        aaData,
      totalDocumentCount: @document_count
    }
  end

private


  def data
    search_data.paginate({:page => page, :per_page => per_page})
  end


  def search_data
    #Couchdb search sucks
    #fetch_search_data_couchdb

    retval ||= fetch_search_data_elasticsearch
  end


  def fetch_search_data_elasticsearch
    puts "INFO: fetching elasticsearch results..."

    @retval = []

    #We are overriding the Datatable search box with our own, so we don't get a
    # params[:sSearch]. We have to use the one we set manually
    if params[:search_val].present?
      search = params[:search_val]
      
      #TODO: do one search instead of two

      #Get doc list, so we can get colnames in common
      options =   {
                    #set the ES from (search offset) field from the last doc search
                    :from => doc_search_page,
                    #set the ES size (how many from search offset) field from the last doc search
                    # per_page method
                    :size => doc_search_per_page
                  }

      options[:flag] = 'f'
      results = ElasticsearchHelper::es_search_dispatcher("es_query_string_search", search, options)

      doc_list = get_docs_from_raw_es_data(results, @current_user)
      colnames = []

      #Don't let unvalidated docs screw up the search results
      validated_doc_list = doc_list.reject {|doc| !doc.validated }
      if !validated_doc_list.empty?
        colnames = get_colnames_in_common(validated_doc_list)
      end

      raw_data = results

      if raw_data
        #Set the total documents found in the results, in case we later
        # determine that we only have document results and the return
        # data is already paginated from ES, so a data.count would be
        # wrong
        @document_count = ElasticsearchHelper.get_document_count

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

          #Only merge in data that this user can view, even though SearchAllDatable would
          # show them any and every doc's metadata
          if doc_is_viewable(doc, @current_user)
            colnames_in_common_and_merge_search =  (!colnames.empty?) && (merge_search)
            if colnames_in_common_and_merge_search && doc.validated
              row["_source"]["data"].map do |data_row| 
                values = []
                colnames.each do |colname|
                  values << data_row[colname]
                end
                @retval << values
              end #end row...map
            end #end if doc.validated
          end #end if doc_is_viewable
        end #end raw_data.collect
      end #end raw_data
    end #if params[:sSearch].present?

    @retval
  end


  def fetch_search_data_cloudant
    @retval = []

    if params[:sSearch].present?
      raw_data = cloudant_search_all_data(params[:sSearch])

      if raw_data
        raw_data.collect do |row|
          doc_name = row["id"]
          score = row["order"][0]
          doc_id = doc_name.sub("Document-", "").to_i

          begin
            doc = Document.find(doc_id)
          rescue ActiveRecord::RecordNotFound
            log_and_print "WARN: Document with id #{doc_id} not found in search. Skipping."
          end

          if doc_is_viewable(doc, @current_user)
            row = {}
            row["0"] = link_to doc.name, doc
            #count col
            row["1"] = score
            @retval << row
          end
        end
      end
    end
    @retval
  end
end

