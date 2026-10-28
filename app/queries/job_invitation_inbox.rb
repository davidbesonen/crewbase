class JobInvitationInbox
  def initialize(user:, company: nil, status: nil)
    @user = user
    @company = company
    @status = status.to_s.presence_in(JobInvitation.statuses.keys)
  end

  def call
    {
      received: company ? [] : invitation_scope(JobInvitation.received_by(user)).to_a,
      sent: invitation_scope(sent_scope).to_a
    }
  end

  private

  attr_reader :user, :company, :status

  def sent_scope
    scope = company ? JobInvitation.where(job_id: company.jobs.select(:id)) : user.sent_job_invitations
    status ? scope.where(status:) : scope
  end

  def invitation_scope(scope)
    scope.includes(:invited_by, { profile: :user }, job: [ :company, :locations ])
      .order(created_at: :desc, id: :desc)
  end
end
