class ConversationParticipants
  def initialize(context:)
    @context = context
  end

  def users
    case context
    when JobApplication
      owners = context.job.company.users.merge(CompanyAssignment.where(role: "owner"))
      [ context.profile.user, *owners ].uniq
    when JobInvitation
      [ context.profile.user, context.invited_by ].uniq
    else
      []
    end
  end

  private

  attr_reader :context
end
