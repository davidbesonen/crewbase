class Usr::JobsController < ApplicationController
  before_action :set_job, only: [ :show ]

  def index
    jobs_scope = Job.includes(:locations, company: :industries)
      .where(is_active: true, status: :published)

    @industries = Industry.order(:name)
    @q = jobs_scope.ransack(params[:q])
    @pagy, @jobs = pagy(@q.result(distinct: true)
      .order(published_at: :desc, created_at: :desc)
    )
  end

  def show
    @company_plan = @job.company&.company_plans&.includes(:plan)&.order(created_at: :desc, id: :desc)&.first&.plan
    @job_application = current_user.user_profile&.job_applications&.find_by(job: @job)
    @saved_job = current_user.saved_jobs.find_by(job: @job)
    @crew_recommendations_path = if @job.multi_position?
      usr_job_crew_path(@job)
    else
      usr_profiles_path(recommended: "1")
    end
    @crew_recommendations = if @job.editable_by?(current_user)
      CrewRecommender.new(user: current_user, jobs: [ @job ]).results
    else
      []
    end
  end

  def my_postings
    owned_company_ids = current_user.owned_companies.select(:id)
    raise ActiveRecord::RecordNotFound unless owned_company_ids.exists?

    @jobs = Job.includes(:locations, :company)
      .where(company_id: owned_company_ids)
      .order(created_at: :desc, id: :desc)
  end

  def select_company
    @companies = current_user.companies
      .where(company_assignments: { role: "owner" })
      .order(:name)
  end

  private

  def set_job
    @job = Job.includes(:locations, company: :industries).find(params[:id])
    return if @job.is_active? && @job.published?
    return if @job.editable_by?(current_user)

    raise ActiveRecord::RecordNotFound
  end
end
