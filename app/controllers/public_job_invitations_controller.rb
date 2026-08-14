class PublicJobInvitationsController < ApplicationController
  skip_before_action :authenticate_user!, only: :show
  before_action :set_invitation

  def show
    @marketing_page = true
    @page_title = "Invitation to apply for #{@invitation.job.title} | Crewbase"
    session[:return_to_after_auth] = public_job_invitation_path(@invitation.token) unless current_user
  end

  def accept
    @invitation.claim!(current_user) unless @invitation.profile
    raise ActiveRecord::RecordNotFound unless @invitation.profile.user == current_user

    @invitation.notification&.mark_as_read!
    redirect_to new_usr_job_job_application_path(@invitation.job)
  end

  private

  def set_invitation
    @invitation = JobInvitation.includes(job: :company).find_by!(token: params[:token])
  end
end
