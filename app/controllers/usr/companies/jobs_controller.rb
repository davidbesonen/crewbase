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
    @job = @company.jobs.new(schedule_has_times: false, posting_type: :single_role, employment_type: :contract, workplace_type: :on_site)
    @job.crew_positions.build
    @job.project = @company.projects.active.find(params[:project_id]) if params[:project_id].present?
    if @job.project
      @job.assign_attributes(starts_at: @job.project.starts_on, ends_at: @job.project.ends_on)
    end
    @job.locations.build if @job.locations.empty?
    prepare_projects
  end

  def create
    return require_company_feature!(@company, :multi_position_gigs) if requested_multi_position?

    @job = @company.jobs.new(job_attributes.merge(created_by: current_user.id))
    @job.require_initial_crew_position = true
    @job.posting_type = nil unless job_params.key?(:posting_type)

    unless active_job_capacity_available?(@job)
      @job.errors.add(:base, active_job_limit_message)
      prepare_failed_job_form
      return render :new, status: :unprocessable_entity
    end

    if save_job_with_requirements
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

    if !was_active && !active_job_capacity_available?(@job)
      @job.errors.add(:base, active_job_limit_message)
      prepare_failed_job_form
      return render :edit, status: :unprocessable_entity
    end

    if save_job_with_requirements
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
    @job = @company.jobs.includes(:project, :locations, :crew_positions, job_requirements: :requirement).find(params[:id])
  end

  def job_params
    params.require(:job).permit(
      :title,
      :workplace_type,
      :employment_type,
      :posting_type,
      :requires_travel,
      :editable_by_company,
      :is_active,
      :status,
      :description,
      *JobExperienceRequirements::TEXT_FIELDS.keys,
      :pay_min,
      :pay_max,
      :pay_period,
      :published_at,
      :starts_at,
      :ends_at,
      :schedule_has_times,
      :archived_at,
      :closed_at,
      :filled_at,
      :application_deadline,
      :project_id,
      required_occupation_ids: [],
      required_capability_keys: [],
      preferred_capability_keys: [],
      required_equipment_family_keys: [],
      preferred_equipment_family_keys: [],
      required_skill_ids: [],
      preferred_skill_ids: [],
      required_equipment_ids: [],
      preferred_equipment_ids: [],
      questions: [],
      work_dates: [],
      crew_positions_attributes: [ :id, :title, :headcount ],
      locations_attributes: [ :id, *SaveJobPosting::LOCATION_FIELDS ]
    )
  end

  def prepare_projects
    @form_location ||= submitted_location
    @entitlement ||= CompanyPlanEntitlement.new(@company)
    projects = @company.projects.active
    projects = projects.or(@company.projects.where(id: @job.project_id)) if @job&.project_id?
    @projects = projects.order(:name).to_a
    @requirement_selections = submitted_requirement_selections
    catalog = OccupationCatalog.new(selected: @job.job_requirements.map(&:requirement))
    @occupations = catalog.records(selected_ids: @requirement_selections[:required_occupation_ids]).to_a
  end

  def requested_multi_position?
    job_params[:posting_type] == "multi_position" && !CompanyPlanEntitlement.new(@company).allowed?(:multi_position_gigs)
  end

  def submitted_requirement_selections
    return {} unless params[:job].present?

    job_params.slice(*REQUIREMENT_PARAMETER_KEYS).to_h.symbolize_keys
  end

  def job_attributes
    attributes = job_params.except(:locations_attributes, *REQUIREMENT_PARAMETER_KEYS).merge(publication_attributes)
    return attributes unless attributes[:project_id].present?
    return attributes if @job&.persisted? && attributes[:project_id].to_s == @job.project_id.to_s

    attributes.merge(project_id: @company.projects.active.find(attributes[:project_id]).id)
  end

  def publication_attributes
    case params[:publication_action]
    when "publish" then { status: "published", is_active: true }
    when "draft" then { status: "draft" }
    else {}
    end
  end

  def save_job_with_requirements
    @form_location = submitted_location
    SaveJobPosting.new(job: @job, actor: current_user,
      requirements: requirement_selections? ? requirement_selections : {},
      location: @form_location, replace_location: job_params.key?(:locations_attributes)).call
  rescue ActiveRecord::RecordInvalid => error
    error.record.errors.each { |attribute, message| @job.errors.add(attribute, message) } unless error.record == @job
    false
  end

  def requirement_selections
    selections = job_params.slice(*REQUIREMENT_PARAMETER_KEYS).to_h.symbolize_keys
    # A modern form's personal entries take precedence over stale catalog IDs.
    JobExperienceRequirements::TEXT_FIELDS.each do |field, (type, importance)|
      selections.delete(:"#{importance}_#{type.underscore}_ids") if job_params.key?(field)
    end
    selections
  end

  def requirement_selections?
    JobRequirementsUpdater::SELECTIONS.keys.any? { |key| job_params.key?(key) }
  end

  def job_destination(job)
    job.project ? usr_project_path(job.project) : usr_company_path(@company)
  end

  def submitted_location
    return unless params[:job].present? && job_params.key?(:locations_attributes)

    fields = job_params.fetch(:locations_attributes).values.first
    Location.new(fields.to_h.symbolize_keys.slice(*SaveJobPosting::LOCATION_FIELDS)
      .transform_values { |value| value.to_s.strip.presence })
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
