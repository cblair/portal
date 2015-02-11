class UploadsDatatable

  delegate :params, :h, :link_to, :number_to_human_size, to: :@view

  def initialize(view,current_user)
    @view = view
    @current_user = current_user
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Upload.count,
      iTotalDisplayRecords: uploads.total_entries,
      aaData: data
    }
  end

  private
  
  def data

    uploads.map do |upload|
      [
        link_to(upload.upfile_file_name, upload),
        number_to_human_size(upload.upfile_file_size),
        h(upload.upload_type),
        link_to('Destroy', upload, confirm: 'Are you sure?  Note: deleting an upload does not delete the associated document (if it exists).  See "help"', method: :delete, :class => 'btn btn-mini btn-danger')
      ]
    end
  end
  
  def uploads
    @uploads ||= fetch_uploads
  end

  #Get upload records
  def fetch_uploads
    uploads = Upload.where(:user_id => @current_user.id).order("#{sort_column} #{sort_direction}")
    uploads = uploads.page(page).per_page(per_page)
    
    if params[:sSearch].present?
      uploads = uploads.where("name like :search or upfile_file_name like :search", search: "%#{params[:sSearch]}%")
    end
    
    return uploads
  end


  #Pagination settings
  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[upfile_file_name upfile_file_size upload_type]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end

end
