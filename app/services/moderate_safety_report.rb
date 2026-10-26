class ModerateSafetyReport
  def initialize(report:, moderator:, status:, notes:)
    @report, @moderator, @status, @notes = report, moderator, status, notes
  end

  def call
    @report.with_lock do
      decision = @report.moderation_decisions.create!(moderator: @moderator, previous_status: @report.status, status: @status, notes: @notes)
      @report.update!(status: @status)
      AdminAuditEvent.create!(actor: @moderator, subject: @report, action: "moderation_decision", reason: @notes,
        changeset: { "status" => [ decision.previous_status, decision.status ] })
      decision
    end
  end
end
