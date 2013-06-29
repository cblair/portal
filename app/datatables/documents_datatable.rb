#This Document Datatable class is for searching data in the document

class DocumentsDatatable
  include DocumentsHelper
  include SearchesHelper

  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view, document)
    @view = view
    @document = document
  end


  def as_json(options = {})
    {
      sEcho:params[:sEcho].to_i,
      iTotalRecords:@document.stuffing_data.count,  #total before filtering
      iTotalDisplayRecords:data.count,              #total after filtering
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
    document_data
  end


  def document_data
    #@documents ||= fetch_documents
    fetch_document_data
  end


  def fetch_document_data
    if params[:sSearch].present?
      raw_data = couch_search_row_by_doc_and_data(@document.id,params[:sSearch])
      return_data = raw_data.collect {|datum| datum["value"] }
    else
      return_data = @document.stuffing_data
    end

    return_data = return_data.map do |row| 
      values = []
      row.each do |key, val|
        #if the value is in the foreign keys, add links and icons for search
        if (@document.stuffing_foreign_keys and @document.stuffing_foreign_keys.include?(key))
          #set the default search value to "column:value" for Lucene format
          default_search = "#{key}:#{val}"
          text = "<a href=\"/searches/new?default_search=#{default_search}\"><i class=\"icon-sitemap\"></i></a> "
          text += "#{val}"
          values << text
        else
          values << val
        end
      end
      values
    end

    #return_data = return_data.paginate({:page => page, :per_page => per_page})

    return_data
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
