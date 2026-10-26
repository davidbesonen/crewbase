class JobInvitationMailer < ApplicationMailer
  def invite
    @invitation = params[:invitation]
    @job = @invitation.job
    recipient = @invitation.profile&.user || User.find_by("LOWER(email) = ?", @invitation.email.to_s.downcase)
    return unless @invitation.pending? && @job.accepting_applications?
    return if recipient && !recipient.email_notifications_enabled?
    return if UserBlock.between?(@invitation.invited_by, recipient)

    mail(to: @invitation.email, subject: "You're invited to apply for #{@job.title}")
  end
end
