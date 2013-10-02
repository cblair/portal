class SearchAllDatatable
  include SearchesHelper
  include SearchesDatatableHelper
  include ElasticsearchHelper
  require 'will_paginate/array'

  delegate :params, :h, :link_to, :document_path, to: :@view

  @document_results = true
  attr_accessor :document_results

  def initialize(view, current_user)
    @view = view
    @current_user = current_user
  end

  def as_json(options = {})
    #Get our search data now, so we set all the search side affects
    # now (i.e. counts, modes, etc.)
    aaData = search_data

    {
      sEcho:params[:sEcho].to_i,
      #TODO: count functions for document_results == true
      iTotalRecords: @document_count,
      iTotalDisplayRecords: @document_count,
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
    search_data
  end


  def search_data
    #Couchdb search sucks
    #fetch_search_data_couchdb

    retval ||= fetch_search_data_elasticsearch
  end


  def fetch_search_data_couchdb
    @retval = []

    if params[:sSearch].present?
      search = params[:sSearch]
      raw_data = couch_search_count_data_in_document(search)

      if raw_data
        raw_data.each do |raw_datum|          
          raw_datum["value"].collect do |doc_name, count|
            doc_id = doc_name.sub("Document-", "").to_i

            begin
              doc = Document.find(doc_id)
            rescue ActiveRecord::RecordNotFound
              log_and_print "WARN: Document with id #{doc_id} not found in search. Skipping."
            end

            if doc_is_viewable(doc, @current_user)
              row = {}
              #search col
              row["0"] = raw_datum['key'].first
              #document col
              row["1"] = link_to doc.name, doc
              #count col
              row["2"] = count
              @retval << row
            end
          end
        end
      end

      @retval = @retval.paginate({:page => page, :per_page => per_page})
    else
      @retval = []
    end

    @retval
=begin
    documents = Document.order("#{sort_column} #{sort_direction}")
    documents = documents.page(page).per_page(per_page)
    if params[:sSearch].present?
      documents = documents.where("name like :search or category like :search", search: "%#{params[:sSearch]}%")
    end
    documents
=end
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
                    #set the ES from (search offset) field from our page method
                    :from => page,
                    #set the ES size (how many from search offset) field from our
                    # per_page method
                    :size => per_page
                  }

      #options[:flag] = 'm'
      options[:flag] = 'f'
      results = ElasticsearchHelper::es_search_dispatcher("es_query_string_search", search, options)

      doc_list = get_docs_from_raw_es_data(results, @current_user)
      colnames = []

      #Don't let unvalidated docs screw up the search results
      validated_doc_list = doc_list.reject {|doc| !doc.validated }
      if !validated_doc_list.empty?
        colnames = get_colnames_in_common(validated_doc_list)
      end

      #Get data results
      #options[:flag] = 'f'
      #raw_data = ElasticsearchHelper::es_search_dispatcher("es_query_string_search", search, options)
      raw_data = results

      #sfield = "Survey_Year" #SAS TODO: get field name from user?
      #raw_data = es_terms_facet(search, sfield) #SAS makes ES query
      
      #SAS ES range any
      #qfrom = 984.682  #exmaple only
      #qto = 1762.803  #exmaple only
      #sfield = "Map_Segment_Length_M "  #exmaple only
      #raw_data = es_range_facet(qfrom, qto, sfield)

      #SAS ES date format yyyy/mm/dd, ATM mm/dd/yyyy ex: 7/6/2004
      #qfrom = "2004/7/6"  #exmaple only
      #qto = "2004/7/7"  #exmaple only
      #sfield = "Survey_Start_Date"  #exmaple only
      #raw_data = es_date_range_facet(qfrom, qto, sfield)
      
      #SAS ES date histogram, interval -> "day", "month", etc.
      #sfield = "Survey_Start_Date"  #exmaple only
      #myinterval = "day"
      #raw_data = es_date_histogram_facet(sfield, myinterval)
      
      #SAS Test function only
      #sfield = "Survey_Year" #SAS TODO: get field name from user?
      #raw_data = es_test(search, sfield) #SAS makes ES query
      
      #SAS Test function only
      #raw_data = elastic_search_url(search)

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

          #We're displaying documents not usually visible, but we have to be carefull on
          #what metadate we expose.
          #if doc_is_viewable(doc, @current_user)
          if true
            #If there are no colnames in common, just return a list of document links
            colnames_in_common_and_merge_search =  (!colnames.empty?) && (merge_search)
            if !colnames_in_common_and_merge_search
              @document_results = true

              #Make Popover content
              # Metadata
              popover_content = "(no metadata)"
              if doc.stuffing_metadata
                key_values_list = doc.stuffing_metadata.collect do |md|
                  "<tr><td>" + md.keys.first + "</td><td>" + md.values.first + "</td></tr>"
                end
                popover_content = "<table>"
                popover_content += key_values_list.join
                popover_content += "</table>"
              end

              #Colnames
              doc_colnames = get_data_colnames(doc.stuffing_data)
              if doc_colnames
                popover_content += "<b>Column names:</b>"
                popover_content += '<table>'
                popover_content += doc_colnames.collect {|doc_colname| "<tr><td>" + doc_colname + "</td></tr>" }.join
                popover_content += "</table>"
              end

              popover_html = '<a href="' + document_path(doc) + '" class="btn btn-lg btn-info doc-popover" data-toggle="popover" title="" data-content="' + popover_content + '" data-original-title="Metadata">Metadata</a>'
              popover_html = '<div style="font-size:x-small">' + popover_html.html_safe + '</div>'

              @retval << [link_to(doc.name, doc), popover_html]
            end #end if doc.validated
          end #end if doc_is_viewable
        end #end raw_data.collect
      end #end raw_data
    end #if params[:sSearch].present?

    @retval
  end
end
