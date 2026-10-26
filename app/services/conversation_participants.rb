class ConversationParticipants
  def initialize(context:)
    @context = context
  end

  def users
    case context
    when JobApplication, JobInvitation
      owners = context.job.company.users.merge(CompanyAssignment.where(role: "owner"))
      [ context.profile&.user, *owners ].compact.uniq
    else
      []
    end
  end

  private

  attr_reader :context
end
