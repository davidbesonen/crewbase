class Usr::JobApplicationsController < ApplicationController
  before_action :ensure_profile_present
  before_action :set_job, only: [ :new, :create ]
  before_action :set_job_application, only: [ :show, :update_status, :add_credit ]
  before_action :ensure_job_application_review_access!, only: [ :update_status ]

  def index
    @job_applications = applicant_profile.job_applications
      .includes(job: [ :company, :locations ])
      .order(created_at: :desc)
    invitations = applicant_profile.job_invitations
      .includes(job: [ :company, :locations ])
      .order(created_at: :desc)
    @pending_job_invitations = invitations.pending
    @past_job_invitations = invitations.where.not(status: :pending)
  end

  def show
    @pipeline_available = @company_owner_view && CompanyPlanEntitlement.new(@job.company).allowed?(:shortlists_pipeline)
    @offers = @job_application.job_offers.order(created_at: :desc)
    @conversation = @job_application.conversation
    @existing_credit = applicant_profile.credits.find_by(job: @job)
    @available_crew_positions = available_crew_positions if @company_owner_view && @job.multi_position?
  end

  def add_credit
    head :not_found
  end

  def update_status
    status = params[:status].to_s

    unless JobApplication.review_statuses.include?(status)
      redirect_to usr_job_application_path(@job_application), alert: "Status is invalid for review."
      return
    end

    if status == "accepted"
      accept_for_position
    else
      result = ReviewJobApplication.new(application: @job_application, reviewer: current_user, status:).call
      if result.success?
        redirect_to usr_job_application_path(@job_application), notice: "Application status updated to #{status.humanize.titleize}."
      else
        redirect_to usr_job_application_path(@job_application), alert: result.error
      end
    end
  end

  def new
    existing_job_application = applicant_profile.job_applications.find_by(job: @job)
    if existing_job_application.present?
      redirect_to usr_job_application_path(existing_job_application), notice: "You have already applied to this job."
      return
    end

    @job_application = @job.job_applications.new(profile: applicant_profile)
  end

  def create
    @job_application = @job.job_applications.new(job_application_params)
    @job_application.profile = applicant_profile
    @job_application.status ||= :submitted

    invitation = applicant_profile.job_invitations.pending.find_by(job: @job)

    if SubmitJobApplication.new(application: @job_application, invitation:).call
      redirect_to usr_job_path(@job), notice: "Application submitted successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def ensure_profile_present
    return unless needs_profile_setup?(current_user)

    redirect_to usr_onboarding_path
  end

  def set_job
    @job = Job.includes(:company, :locations).find(params[:job_id])
    raise ActiveRecord::RecordNotFound unless @job.is_active? && @job.published?
    return if @job.accepting_applications?

    redirect_to usr_job_path(@job), alert: "This job is no longer accepting applications."
  end

  def set_job_application
    @job_application = JobApplication
      .includes(:profile, { profile: :user }, job: [ :company, :locations ])
      .find(params[:id])
    @job = @job_application.job
    @company_owner_view = @job_application.reviewable_by?(current_user)

    return if @job_application.profile == applicant_profile || @company_owner_view

    raise ActiveRecord::RecordNotFound
  end

  def applicant_profile
    current_user.user_profile
  end

  def ensure_job_application_review_access!
    return if @company_owner_view

    raise ActiveRecord::RecordNotFound
  end

  def job_application_params
    params.require(:job_application).permit(
      :resume,
      :cover_letter_file,
      :additional_information,
      attachments: [],
      question_answers: {}
    )
  end

  def accept_for_position
    redirect_to new_usr_job_offer_path(job_application_id: @job_application.id, crew_position_id: params[:crew_position_id])
  end

  def available_crew_positions
    @job.crew_positions
      .left_joins(:crew_assignments)
      .group(:id)
      .having("COUNT(crew_assignments.id) < crew_positions.headcount")
      .order(:title)
  end
end
