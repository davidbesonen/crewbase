class Usr::JobBriefsController < ApplicationController
  def show
    @job = Job.includes(:company, :venue, :locations).find(params[:job_id])
    raise ActiveRecord::RecordNotFound unless @job.company.is_owner?(current_user) || @job.hired?(current_user)
    @brief = JobBrief.new(job: @job)
    response.headers["Cache-Control"] = "private, no-store"
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
  end
end
