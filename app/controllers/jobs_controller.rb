class JobsController < ApplicationController
  #include JobsHelper
  
  before_filter :require_permissions
  #load_and_authorize_resource #CanCan
  
  def require_permissions
    if params.include?("id")
      job = Job.find(params[:id])
      
      if job.user_id != current_user.id
        flash[:error] = "Job not found, or you do not have permissions for this action."
        redirect_to jobs_path
      end
    end
  end

  # GET /jobs
  # GET /jobs.json
  def index
    #@jobs = Job.where(:user_id => current_user.id) #not needed?

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: JobsDatatable.new(view_context) }
    end
  end

  # GET /jobs/1
  # GET /jobs/1.json
  def show
    @job = Job.find(params[:id])
    @delayed_job = Delayed::Job.where(:job_id => @job.id).first

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @job }
    end
  end

  # GET /jobs/new
  # GET /jobs/new.json
  def new
    @job = Job.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @job }
    end
  end

  # GET /jobs/1/edit
  def edit
    @job = Job.find(params[:id])
  end

  # POST /jobs
  # POST /jobs.json
  def create
    @job = Job.new(params[:job])

    respond_to do |format|
      if @job.save
        format.html { redirect_to @job, notice: 'Job was successfully created.' }
        format.json { render json: @job, status: :created, location: @job }
      else
        format.html { render action: "new" }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /jobs/1
  # PUT /jobs/1.json
  def update
    @job = Job.find(params[:id])

    respond_to do |format|
      if @job.update_attributes(params[:job])
        format.html { redirect_to @job, notice: 'Job was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @job.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /jobs/1
  # DELETE /jobs/1.json
  def destroy
    @job = Job.find(params[:id])
    @job.destroy

    respond_to do |format|
      format.html { redirect_to jobs_url }
      format.json { head :no_content }
    end
  end

  def clear_jobs
    clear_type = params[:type] or nil

    if clear_type == "selected"
      doc_ids = params["doc_ids"] or []
      doc_ids.each do |doc_id|
        job = Job.find(doc_id.to_i)

	      #TODO: check if user_id == current_user.id

        if job != nil
          #destroy delayed_job first
          d_jobs = Delayed::Job.where(:job_id => job.id)

          #should only be one, but iterate anyway
          d_jobs.each do |dj|
            dj.destroy
          end

          job.destroy
        end
      end
    elsif clear_type == "finished"
      Job.destroy_all(:user_id => current_user.id, :finished => true)
    elsif clear_type == "all"
      Job.destroy_all(:user_id => current_user.id)
    end

    respond_to do |format|
      format.html { redirect_to jobs_url }
      format.json { head :no_content }
    end
  end
end
