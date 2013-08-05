class SearchAllDatatable
  include SearchesHelper
  include ElasticsearchHelper
  require 'will_paginate/array'

  delegate :params, :h, :link_to, to: :@view

  def initialize(view, current_user)
    @view = view
    @current_user = current_user
  end


  def as_json(options = {})
    {
      sEcho:params[:sEcho].to_i,
      iTotalRecords:data.count,
      iTotalDisplayRecords:data.count,
      aaData:
        #Format:
        #  [
        #    ["test","",nil],
        #    ["test","",nil]
        #  ]
        data.paginate({:page => page, :per_page => per_page})
    }
  end


private


  def data
    search_data
  end


  def search_data
    #@documents ||= fetch_documents

    #Couchdb search sucks
    #fetch_search_data_couchdb
    fetch_search_data_elasticsearch
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
              log_and_print "WARN: Document with id #{doc_id} not found in search. Skipping. Raw search return data:"
              puts raw_datum
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


  def fetch_search_data_elasticsearch
    @retval = []

    #We are overriding the Datatable search box with our own, so we don't get a
    # params[:sSearch]. We have to use the one we set manually
    if params[:search_val].present?
      search = params[:search_val]
      
      #TODO: do one search instead of two
      #Get doc list, so we can get colnames in common
      results = elastic_search_all_and_return_doc_ids(search, @current_user)
      doc_list = results.collect {|id| Document.find(id)}
      colnames = []
      if !doc_list.empty?
        colnames = get_colnames_in_common(doc_list)
      end

      #Get data results
      #raw_data = elastic_search_all_data(search) #Orignal
      #raw_data = elastic_search_url(search)
      raw_data = elastic_search_all_data(search, mode="full")
      
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
        raw_data.collect do |row|
          doc_name = row["_source"]["_id"]
          score = row["_score"]
          doc_id = doc_name.sub("Document-", "").to_i

          begin
            doc = Document.find(doc_id)
          rescue ActiveRecord::RecordNotFound
            log_and_print "WARN: Document with id #{doc_id} not found in search. Skipping. Raw search return data:"
            puts raw_data
            next
          end

          if doc_is_viewable(doc, @current_user)
            row["_source"]["data"].map do |data_row| 
              values = []
=begin
              data_row.each do |key, val|
                values << val
              end
=end
              colnames.each do |colname|
                values << data_row[colname]
              end
              @retval << values
            end
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
            log_and_print "WARN: Document with id #{doc_id} not found in search. Skipping. Raw search return data:"
            puts raw_data
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


  def page
    params[:iDisplayStart].to_i/per_page + 1
  end


  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end


  def sort_column
    columns = %w[name category released_on price]
    columns[params[:iSortCol_0].to_i]
  end


  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end
