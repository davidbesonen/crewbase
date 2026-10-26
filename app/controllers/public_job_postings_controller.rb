class PublicJobPostingsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @job = Job.includes(:locations, { job_requirements: :requirement }, company: :industries)
      .not_moderated.where(is_active: true, status: :published)
      .find(params[:id])
    @experience_requirements = JobExperienceRequirements.new(@job).entries
    @marketing_page = true
    @page_title = "#{@job.title} at #{@job.company.name} | Crewbase"
    session[:return_to_after_auth] = public_job_posting_path(@job) unless current_user
  end
end
