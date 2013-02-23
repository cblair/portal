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
    documents.map do |doc|
      [
        link_to(doc.name, doc),
        link_to('Show', doc),
        link_to('Destroy', doc, confirm: 'Are you sure?', method: :delete)
      ]
    end
  end


  def documents
    @documents ||= fetch_documents
  end


  def fetch_documents
    #@documents_all = Document.order("#{sort_column} #{sort_direction}")

    if params[:sSearch].present?
      @documents_all = Document.where(
                                      "collection_id=:collection_id AND name like :search", 
                                      collection_id: @collection_id, 
                                      search: "%#{params[:sSearch]}%"
                                      )
    end

    documents = []
    @documents_all.each do |doc|
      if doc_is_viewable(doc, @current_user)
        documents << doc
      end
    end

    #debugger
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