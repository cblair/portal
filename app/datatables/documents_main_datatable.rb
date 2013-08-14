#This Document Datatable class is for searching document names

class DocumentsMainDatatable
  require 'will_paginate/array'

  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  #TODO: this functions is not allowing us to pass a copy of params[:collection_id).
  #     need to fix
  def initialize(view, current_user)
    @view = view
    @current_user = current_user
    @collection_id = params[:collection_id].to_i #sanitize

    @documents_all = Document.where(:collection_id => @collection_id).order("#{sort_column} #{sort_direction}")
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: @documents_all.count,
      iTotalDisplayRecords: @documents_all.count,
      aaData: data
    }
  end

private

  def data
    #TODO: add this when we figure out how to make datatables refresh on destroy: remote: :true)
    documents.map do |doc|
      validation_text = "<i class=\"label label-important\">Unvalidated</i>"
      if doc.validated 
        validation_text = "<i class=\"label label-info\">Validated</i>"
      end

      [
        link_to(doc.name, doc),
        validation_text,
        link_to('Destroy', doc, { :confirm => 'Are you sure?', 
                                  :class => "label label-important", 
                                  :method => :delete})
      ]
    end
  end


  def documents
    @documents ||= fetch_documents
  end


  def fetch_documents
    if params[:sSearch].present?
      @documents_all = Document.where(
                                      "collection_id=:collection_id AND name like :search", 
                                      collection_id: @collection_id, 
                                      search: "%#{params[:sSearch]}%"
                                      )
    end
#=begin
    documents = []
    @documents_all.each do |doc|
      if doc_is_viewable(doc, @current_user)
        documents << doc
      end
    end
#=end
    documents = documents.paginate({:page => page, :per_page => per_page})
    #page).per_page(per_page)

    documents
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[name]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end