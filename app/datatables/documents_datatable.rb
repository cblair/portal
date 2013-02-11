class DocumentsDatatable
  delegate :params, :h, :link_to, :number_to_currency, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho:params[:sEcho].to_i,
      iTotalRecords:data.count,
      iTotalDisplayRecords:data.total_entries,
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
    document_data
  end

  def document_data
    #@documents ||= fetch_documents
    fetch_document_data
  end

  def fetch_document_data
    data = Document.find(params[:id]).stuffing_data.map {|row| row.values}
    data = data.paginate({:page => page, :per_page => per_page})
    data
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
