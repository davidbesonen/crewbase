class UpdateProductionBrief
  def initialize(job:, actor:, attributes:)
    @job, @actor, @attributes = job, actor, attributes
  end

  def call
    @job.transaction do
      @job.update!(@attributes)
      SyncJobVenue.new(job: @job).call if @job.saved_change_to_venue_id?
      NotifyProductionCrew.new(job: @job, actor: @actor).call if @job.saved_changes.except("updated_at").any?
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
