class Usr::JobCrewsController < ApplicationController
  include CompanyFeatureEnforcement
  before_action :set_owned_job
  before_action :require_staffing_feature

  def show
    @positions = @job.crew_positions.includes(crew_assignments: { profile: :user }).order(:id)
    @candidates = JobCrewCandidateQuery.new(job: @job, user: current_user).candidates
    @schedule_rows = JobCrewSchedule.new(job: @job).rows
    @crew_search_results = JobCrewSearch.new(
      job: @job,
      user: current_user,
      occupation_id: params[:occupation_id],
      skill_id: params[:skill_id],
      equipment_id: params[:equipment_id],
      availability_state: params[:availability_state]
    ).results
    @occupations = Occupation.order(:name).to_a
    @skills = Skill.order(:name).to_a
    @equipment = Equipment.order(:name).to_a
    @crew_shortlists = @job.company.crew_shortlists.order(:name).to_a
  end

  private

  def set_owned_job
    @job = Job
      .joins(company: :company_assignments)
      .find_by!(
        id: params[:job_id],
        posting_type: :multi_position,
        company_assignments: { user_id: current_user.id, role: "owner" }
      )
  end

  def require_staffing_feature
    require_company_feature!(@job.company, :multi_position_gigs)
  end
end
