class JobInvitationInbox
  def initialize(user:)
    @user = user
  end

  def call
    {
      received: invitation_scope(JobInvitation.received_by(user)).to_a,
      sent: invitation_scope(user.sent_job_invitations).to_a
    }
  end

  private

  attr_reader :user

  def invitation_scope(scope)
    scope.includes(:invited_by, { profile: :user }, job: [ :company, :locations ])
      .order(created_at: :desc, id: :desc)
  end
end
