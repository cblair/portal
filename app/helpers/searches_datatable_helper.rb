module SearchesDatatableHelper
  def page
    #params[:iDisplayStart].to_i/per_page + 1
    params[:iDisplayStart].to_i + 1
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

  def merge_search
    params["merge_search"] == "true"
  end
end