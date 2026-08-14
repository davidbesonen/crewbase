class Usr::SavedJobsController < ApplicationController
  before_action :set_job, only: [ :create, :destroy ]

  def index
    @saved_jobs = current_user.saved_jobs
      .includes(job: [ :locations, { company: :industries } ])
      .order(created_at: :desc)
  end

  def create
    current_user.saved_jobs.find_or_create_by!(job: @job)
    redirect_back fallback_location: usr_job_path(@job), notice: "Job saved."
  end

  def destroy
    current_user.saved_jobs.find_by(job: @job)&.destroy!
    redirect_back fallback_location: usr_job_path(@job), notice: "Job removed from saved jobs."
  end

  private

  def set_job
    @job = Job.where(is_active: true, status: :published).find(params[:job_id])
  end
end
