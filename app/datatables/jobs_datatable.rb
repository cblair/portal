class JobsDatatable
  delegate :params, :h, :link_to, :t, :l, :edit_job_path, :job_path, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      sEcho: params[:sEcho].to_i,
      iTotalRecords: Job.count,
      iTotalDisplayRecords: jobs.total_entries,
      aaData: data
    }
  end

private

  def data
    jobs.map do |job|
      status_text = "<i class=\"icon-refresh icon-spin\"></i> Processing..."
      if job.finished == true
        status_text = "<i class=\"icon-check\">Finished</i>"
      end

      job_user = User.where(:id => job.user_id).first
      user_email = ""
      if job_user != nil
        user_email = job_user.email
      end

      actions_text = link_to I18n.t('.edit', :default => I18n.t("helpers.links.edit")),
                      edit_job_path(job), :class => 'btn btn-mini'
      if job.finished == true
        actions_text += link_to(I18n.t('.destroy', :default => I18n.t("helpers.links.destroy")),
                        job_path(job),
                        :method => :delete,
                        :data => { :confirm => I18n.t('.confirm', :default => I18n.t("helpers.links.confirm", :default => 'Are you sure?')) },
                        :class => 'btn btn-mini btn-danger',
                        #TODO: enable this when resubmit datatable query
                        #:remote => true
                        )
      end
      
      [
        link_to(job.id, job_path(job)),
        h(job.description),
        h(user_email),
        status_text,
        l(job.created_at),
        actions_text
      ]
    end
  end

  def jobs
    @jobs ||= fetch_jobs
  end

  def fetch_jobs
    search = params[:sSearch]

    jobs = Job.order("#{sort_column} #{sort_direction}")
    jobs = jobs.page(page).per_page(per_page)

    if search.present?

      #If we get an error, the search term is a string, so only search string 
      # columns
      begin
        Integer(search)
        jobs = jobs.where("id=:search_lit or description like :search", 
          search: "%#{search}%", search_lit: search)
      rescue ArgumentError
        jobs = jobs.where("description like :search", 
          search: "%#{search}%", search_lit: search)
      end

    end
    jobs
  end

  def page
    params[:iDisplayStart].to_i/per_page + 1
  end

  def per_page
    params[:iDisplayLength].to_i > 0 ? params[:iDisplayLength].to_i : 10
  end

  def sort_column
    columns = %w[id description user_id created_at]
    columns[params[:iSortCol_0].to_i]
  end

  def sort_direction
    params[:sSortDir_0] == "desc" ? "desc" : "asc"
  end
end