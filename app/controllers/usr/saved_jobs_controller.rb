class Usr::SavedJobsController < ApplicationController
  before_action :set_job, only: :create

  def index
    @collection = SavedJobCollection.new(user: current_user, status: params[:status], query: params[:q])
    @pagy, @saved_jobs = pagy(@collection.results)
  end

  def create
    current_user.saved_jobs.find_or_create_by!(job: @job)
    redirect_back fallback_location: usr_job_path(@job), notice: "Job saved."
  end

  def destroy
    saved_job = current_user.saved_jobs.find_by!(job_id: params[:job_id])
    job = saved_job.job
    saved_job.destroy!
    fallback = job.publicly_visible? ? usr_job_path(job) : usr_saved_jobs_path
    redirect_back fallback_location: fallback, notice: "Job removed from saved jobs."
  end

  private

  def set_job
    @job = Job.accepting_applications.find(params[:job_id])
  end
end
