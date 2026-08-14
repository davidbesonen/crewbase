class Usr::Companies::JobsController < ApplicationController
  include CompanyFeatureEnforcement
  REQUIREMENT_PARAMETER_KEYS = JobRequirementsUpdater::SELECTIONS.keys.freeze

  before_action :set_company
  before_action :set_job, only: [ :edit, :update, :destroy ]

  def index
    @jobs = @company.jobs.order(created_at: :desc)
  end

  def new
    @entitlement = CompanyPlanEntitlement.new(@company)
    @job = @company.jobs.new
    @job.posting_type = nil
    @job.crew_positions.build
    @job.project = @company.projects.active.find(params[:project_id]) if params[:project_id].present?
    @job.locations.build if @job.locations.empty?
    prepare_projects
  end

  def create
    return require_company_feature!(@company, :multi_position_gigs) if requested_multi_position?

    @job = @company.jobs.new(job_attributes)
    @job.require_initial_crew_position = true
    @job.posting_type = nil unless job_params.key?(:posting_type)
    apply_status_timestamp(@job)

    unless active_job_capacity_available?(@job)
      @job.errors.add(:base, active_job_limit_message)
      prepare_failed_job_form
      return render :new, status: :unprocessable_entity
    end

    if save_job_with_requirements
      location = find_or_create_location
      @job.locations << location if location && !@job.locations.include?(location)
      redirect_to job_destination(@job), notice: "Job created successfully!"
    else
      @job.crew_positions.build if @job.crew_positions.empty?
      @job.locations.build if @job.locations.empty?
      prepare_projects
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @entitlement = CompanyPlanEntitlement.new(@company)
    @job.locations.build if @job.locations.empty?
    prepare_projects
  end

  def update
    return require_company_feature!(@company, :multi_position_gigs) if requested_multi_position?

    was_active = active_job?(@job)
    @job.assign_attributes(job_attributes)
    apply_status_timestamp(@job)

    if !was_active && !active_job_capacity_available?(@job)
      @job.errors.add(:base, active_job_limit_message)
      prepare_failed_job_form
      return render :edit, status: :unprocessable_entity
    end

    if save_job_with_requirements
      replace_location
      redirect_to job_destination(@job), notice: "Job updated successfully!"
    else
      @job.locations.build if @job.locations.empty?
      prepare_projects
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @job.destroy
    redirect_to usr_company_jobs_path(@company), notice: "Job deleted successfully!"
  end

  private

  def set_company
    @company = Company.joins(:company_assignments)
      .find_by!(
        id: params[:company_id],
        company_assignments: { user_id: current_user.id, role: "owner" }
      )
    @entitlement = CompanyPlanEntitlement.new(@company)
  end

  def set_job
    @job = @company.jobs.find(params[:id])
  end

  def job_params
    params.require(:job).permit(
      :title,
      :workplace_type,
      :employment_type,
      :posting_type,
      :requires_travel,
      :is_visa_sponsorship_available,
      :is_active,
      :status,
      :description,
      :pay_min,
      :pay_max,
      :pay_period,
      :published_at,
      :starts_at,
      :ends_at,
      :archived_at,
      :closed_at,
      :filled_at,
      :application_deadline,
      :created_by,
      :project_id,
      required_occupation_ids: [],
      required_skill_ids: [],
      preferred_skill_ids: [],
      required_equipment_ids: [],
      preferred_equipment_ids: [],
      questions: [],
      work_dates: [],
      crew_positions_attributes: [ :id, :title, :headcount ],
      locations_attributes: [ :id, :address_line_1, :address_line_2, :city, :state, :zip_code, :country ]
    )
  end

  def prepare_projects
    @entitlement ||= CompanyPlanEntitlement.new(@company)
    projects = @company.projects.active
    projects = projects.or(@company.projects.where(id: @job.project_id)) if @job&.project_id?
    @projects = projects.order(:name).to_a
    @occupations = Occupation.order(:name).to_a
    @skills = Skill.order(:name).to_a
    @equipment = Equipment.order(:name).to_a
    @requirement_selections = submitted_requirement_selections
  end

  def requested_multi_position?
    job_params[:posting_type] == "multi_position" && !CompanyPlanEntitlement.new(@company).allowed?(:multi_position_gigs)
  end

  def submitted_requirement_selections
    return {} unless params[:job].present?

    job_params.slice(*REQUIREMENT_PARAMETER_KEYS).to_h.symbolize_keys
  end

  def job_attributes
    attributes = job_params.except(:locations_attributes, *REQUIREMENT_PARAMETER_KEYS)
    return attributes unless attributes[:project_id].present?
    return attributes if @job&.persisted? && attributes[:project_id].to_s == @job.project_id.to_s

    attributes.merge(project_id: @company.projects.active.find(attributes[:project_id]).id)
  end

  def save_job_with_requirements
    Job.transaction do
      @job.save!
      JobRequirementsUpdater.new(job: @job, selections: requirement_selections).call if requirement_selections?
      JobCompletion.new(job: @job).call if @job.completed?
      true
    end
  rescue ActiveRecord::RecordInvalid => error
    error.record.errors.each { |attribute, message| @job.errors.add(attribute, message) } unless error.record == @job
    false
  end

  def requirement_selections
    permitted = job_params
    {
      required_occupation_ids: permitted[:required_occupation_ids],
      required_skill_ids: permitted[:required_skill_ids],
      preferred_skill_ids: permitted[:preferred_skill_ids],
      required_equipment_ids: permitted[:required_equipment_ids],
      preferred_equipment_ids: permitted[:preferred_equipment_ids]
    }
  end

  def requirement_selections?
    JobRequirementsUpdater::SELECTIONS.keys.any? { |key| job_params.key?(key) }
  end

  def job_destination(job)
    job.project ? usr_project_path(job.project) : usr_company_path(@company)
  end

  def find_or_create_location
    locations_attributes = job_params.fetch(:locations_attributes, {}).values.first
    return unless locations_attributes.present?

    attrs = locations_attributes.to_h.symbolize_keys.slice(
      :address_line_1,
      :address_line_2,
      :city,
      :state,
      :zip_code,
      :country
    ).transform_values(&:presence).compact

    return if attrs.empty?

    Location.find_or_create_by(attrs)
  end

  def replace_location
    location = find_or_create_location
    return unless location

    @job.location_assignments.destroy_all
    @job.locations << location
  end

  def apply_status_timestamp(job)
    case job.status
    when "archived"
      job.archived_at ||= Time.current
    when "closed"
      job.closed_at ||= Time.current
    when "filled"
      job.filled_at ||= Time.current
    when "completed"
      job.completed_at ||= Time.current
    when "published"
      job.published_at ||= Time.current
    end
  end

  def active_job_capacity_available?(job)
    return true unless active_job?(job) && active_job_capacity_enforced?

    @entitlement.within_limit?(:active_jobs)
  end

  def active_job?(job)
    job.is_active? && job.published?
  end

  def active_job_capacity_enforced?
    @entitlement.current_plan&.data&.key?("active_jobs_limit")
  end

  def active_job_limit_message
    "#{@entitlement.current_plan.name} plan allows #{@entitlement.limit(:active_jobs)} active jobs. Close or archive a job, or upgrade your plan."
  end

  def prepare_failed_job_form
    @job.crew_positions.build if @job.crew_positions.empty?
    @job.locations.build if @job.locations.empty?
    prepare_projects
  end
end
