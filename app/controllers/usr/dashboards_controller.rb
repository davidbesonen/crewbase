require_dependency Rails.root.join("app/queries/crew_recommender").to_s
require_dependency Rails.root.join("app/queries/worker_job_recommender").to_s
require_dependency Rails.root.join("app/presenters/dashboard_job_posting").to_s

class Usr::DashboardsController < ApplicationController
  before_action :ensure_profile_present

  def index
    @profile = current_user.user_profile
    @profile_completion = @profile.completion_percentage
    @profile_next_step = @profile.next_completion_step
    @availability_overview = @profile.availability_overview
    @owned_companies = current_user.owned_companies
      .distinct
      .order(:name)
      .to_a
    @post_job_path = post_job_path
    @start_project_path = start_project_path
    @owned_job_postings = owned_job_postings
    prepare_owned_job_postings
    prepare_crew_recommendations
    @upcoming_jobs = Job.upcoming.includes(:company).limit(3)

    @job_recommendations = WorkerJobRecommender.new(profile: @profile).results
    recommended_job_ids = @job_recommendations.map { |result| result.job.id }
    @applied_job_ids = @profile.job_applications.where(job_id: recommended_job_ids).pluck(:job_id).to_set
    @current_job_applications = current_user.user_profile.job_applications
      .joins(:job)
      .where.not(jobs: { status: Job.statuses[:filled] })
      .includes(job: [ :company, :locations ])
      .order(created_at: :desc)
      .limit(3)
    @pending_job_invitations = @profile.job_invitations
      .pending
      .includes(job: [ :company, :locations ])
      .order(created_at: :desc)
      .limit(3)
    @recent_notifications = current_user.notifications.recent_first.limit(3)
    @saved_jobs = current_user.saved_jobs.includes(job: :company).order(created_at: :desc).limit(3)
    @crew_shortlists = CrewShortlist
      .joins(company: :company_assignments)
      .where(company_assignments: { user_id: current_user.id, role: "owner" })
      .includes(:company, :crew_shortlist_memberships)
      .order(updated_at: :desc)
      .limit(3)
  end

  def quick_search
    render json: { results: DashboardQuickSearch.new(params[:q]).results }
  end

  private

  def prepare_crew_recommendations
    return if @owned_companies.empty?

    recommendations = ::CrewRecommender.new(user: current_user, companies: @owned_companies)
    @crew_recommendations_active_jobs = recommendations.active_jobs?
    @crew_recommendations = recommendations.results
  end

  def prepare_owned_job_postings
    jobs = @owned_job_postings.to_a
    return if jobs.empty?

    applicant_counts = JobApplication.where(job_id: jobs.map(&:id)).group(:job_id).count
    recommendations = ::CrewRecommender.new(user: current_user, jobs:, limit: nil)
    @owned_job_postings = jobs.map do |job|
      DashboardJobPosting.new(
        job:,
        applicant_count: applicant_counts.fetch(job.id, 0),
        recommended_applicant_count: recommendations.results_for(job).size
      )
    end
  end

  def post_job_path
    return select_company_usr_jobs_path if @owned_companies.many?
    return new_usr_company_job_path(@owned_companies.first) if @owned_companies.one?

    new_usr_company_path
  end

  def start_project_path
    return select_company_usr_projects_path if @owned_companies.many?
    return new_usr_company_project_path(@owned_companies.first) if @owned_companies.one?

    new_usr_company_path
  end

  def owned_job_postings
    return Job.none if @owned_companies.empty?

    Job.includes(:locations, :company)
      .where(company: @owned_companies, is_active: true, status: :published)
      .order(created_at: :desc, id: :desc)
      .limit(3)
  end

  def ensure_profile_present
    return unless needs_profile_setup?(current_user)

    redirect_to edit_usr_profile_path(current_user.user_profile)
  end
end
