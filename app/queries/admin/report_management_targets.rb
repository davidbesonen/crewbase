class Admin::ReportManagementTargets
  def initialize(report)
    @report = report
  end

  def results
    subject = @report.subject
    case subject
    when Profile then [ subject.user ]
    when Credit then [ subject.profile.user ]
    when Review then [ subject.profile.user, review_target(subject.reviewable) ].compact.uniq
    when Job, Company then [ subject ]
    when Conversation then ConversationParticipants.new(context: subject.context).users
    else []
    end
  end

  private

  def review_target(target)
    target.is_a?(Profile) ? target.user : target
  end
end
