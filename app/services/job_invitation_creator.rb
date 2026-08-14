class JobInvitationCreator
  def initialize(job:, invited_by:, profile: nil, email: nil)
    @job = job
    @profile = profile
    @email = email
    @invited_by = invited_by
  end

  def call
    JobInvitation.transaction do
      invitation = JobInvitation.create!(job:, profile:, email:, invited_by:)
      create_notification(invitation) if profile
      invitation
    end
  end

  private

  attr_reader :job, :profile, :email, :invited_by

  def create_notification(invitation)
    Notification.create!(
      recipient: profile.user,
      actor: invited_by,
      notifiable: invitation,
      kind: "job_invitation",
      message: "#{invited_by.full_name} invited you to apply for #{job.title}."
    )
  end
end
