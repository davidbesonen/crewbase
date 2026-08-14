class Usr::Companies::ApplicationsController < ApplicationController
  include CompanyFeatureEnforcement
  before_action :set_owned_company
  before_action :require_pipeline_feature

  def index
    pipeline = CompanyApplicationPipeline.new(company: @company, filters: filter_params)

    @applications = pipeline.results
    @recommendations = ApplicationPipelineRecommendations.new(
      user: current_user,
      applications: @applications
    ).by_application_id
    @jobs = pipeline.jobs
    @stage_counts = pipeline.stage_counts
    @total_count = pipeline.total_count
    @filters = {
      status: pipeline.status,
      job_id: pipeline.job_id,
      project_id: pipeline.project_id,
      query: pipeline.query
    }.compact
    @return_context = staffing_return_context(pipeline.job_id)
    @filters[:return_to] = "staffing" if @return_context
  end

  private

  def set_owned_company
    @company = current_user.owned_companies.find(params[:company_id])
  end

  def filter_params
    params.permit(:status, :job_id, :project_id, :query)
  end

  def staffing_return_context(job_id)
    return unless params[:return_to] == "staffing" && job_id

    job = @company.jobs.find_by(id: job_id)
    return unless job&.multi_position?

    { path: usr_job_crew_path(job), label: "Back to Staff This Gig" }
  end

  def require_pipeline_feature
    require_company_feature!(@company, :shortlists_pipeline)
  end
end
