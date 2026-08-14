class Usr::JobInvitationsController < ApplicationController
  before_action :set_recipient_invitation, only: [ :accept, :decline ]

  def index
    @invitations = JobInvitationInbox.new(user: current_user).call
  end

  def create
    return create_email_invitation if params[:job_id].present?

    profile = Profile.find(params[:profile_id])
    job = Job
      .where(company_id: current_user.owned_companies.select(:id), is_active: true, status: :published)
      .find(invitation_params[:job_id])

    JobInvitationCreator.new(job:, profile:, invited_by: current_user).call
    redirect_to usr_profile_path(profile), notice: "Invitation sent."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to usr_profile_path(profile), alert: error.record.errors.full_messages.to_sentence
  end

  def accept
    @job_invitation.claim!(current_user) if @job_invitation.profile.nil?
    @job_invitation.notification&.mark_as_read!
    redirect_to new_usr_job_job_application_path(@job_invitation.job)
  end

  def decline
    @job_invitation.decline!
    redirect_to usr_job_invitations_path, notice: "Invitation declined."
  end

  private

  def create_email_invitation
    job = Job
      .where(company_id: current_user.owned_companies.select(:id), is_active: true, status: :published)
      .find(params[:job_id])
    invitation = JobInvitationCreator.new(
      job:,
      email: invitation_params[:email],
      invited_by: current_user
    ).call
    JobInvitationMailer.with(invitation:).invite.deliver_later
    redirect_to usr_job_path(job), notice: "Invitation sent to #{invitation.email}."
  rescue ActiveRecord::RecordInvalid => error
    redirect_to usr_job_path(job), alert: error.record.errors.full_messages.to_sentence
  end

  def invitation_params
    params.require(:job_invitation).permit(:job_id, :email)
  end

  def set_recipient_invitation
    @job_invitation = JobInvitation.received_by(current_user).find(params[:id])
  end
end
