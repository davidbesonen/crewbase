class NotifyProductionCrew
  def initialize(job:, actor:)
    @job, @actor = job, actor
  end

  def call
    profile_ids = @job.job_applications.accepted.pluck(:profile_id) + @job.crew_assignments.pluck(:profile_id)
    User.where(id: Profile.where(id: profile_ids).select(:user_id)).where.not(id: @actor.id).find_each do |recipient|
      Notification.create!(recipient:, actor: @actor, notifiable: @job,
        kind: "production_brief_updated", message: "Show information changed for #{@job.title}. Review the latest show brief. Your accepted booking terms are unchanged.")
    end
  end
end
