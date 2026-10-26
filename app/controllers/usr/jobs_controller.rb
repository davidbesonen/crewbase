class Usr::JobsController < ApplicationController
  before_action :set_job, only: [ :show ]

  def index
    jobs_scope = TouringMarketplace.jobs(Job.accepting_applications).includes(:locations, company: :industries)

    @q = jobs_scope.ransack(params.fetch(:q, {}).except(:company_industries_name_eq))
    @filtered = @q.conditions.any?
    @pagy, @jobs = pagy(@q.result(distinct: true)
      .order(published_at: :desc, created_at: :desc)
    )
  end

  def show
    if params[:source] == "recommendation" && ProductEvent.where(user: current_user, job: @job, name: "recommendation_shown", created_at: 30.days.ago..).exists?
      ProductEvent.record(user: current_user, name: "recommendation_viewed", subject: @job, event_key: "#{Date.current}:#{@job.id}")
    end
    @experience_requirements = JobExperienceRequirements.new(@job).entries
    @documents_visible = @job.documents_visible_to?(current_user)
    @contracts = @job.contracts.includes(:uploaded_by, file_attachment: :blob) if @documents_visible
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
    @job = Job.includes(:locations, { job_requirements: :requirement }, company: :industries).find(params[:id])
    return if @job.publicly_visible?
    return if @job.editable_by?(current_user) || @job.hired?(current_user)

    raise ActiveRecord::RecordNotFound
  end
end
