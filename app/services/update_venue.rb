class UpdateVenue
  def initialize(venue:, actor:, attributes:)
    @venue, @actor, @attributes = venue, actor, attributes
  end

  def call
    @venue.transaction do
      @venue.update!(@attributes)
      if @venue.saved_changes.except("updated_at").any?
        @venue.jobs.not_ended.where.not(status: %i[archived completed]).find_each do |job|
          SyncJobVenue.new(job:).call
          NotifyProductionCrew.new(job:, actor: @actor).call
        end
      end
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
