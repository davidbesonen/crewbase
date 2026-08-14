class JobInvitationMailer < ApplicationMailer
  def invite
    @invitation = params[:invitation]
    @job = @invitation.job
    mail(to: @invitation.email, subject: "You're invited to apply for #{@job.title}")
  end
end
