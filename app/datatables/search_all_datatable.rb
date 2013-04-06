class SearchAllDatatable
  include SearchesHelper
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
        data
    }
  end


private


  def data
    search_data
  end


  def search_data
    #@documents ||= fetch_documents
    fetch_search_data
  end


  def fetch_search_data
    @retval = []

    if params[:sSearch].present?
      raw_data = couch_search_count_data_in_document(params[:sSearch])

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
