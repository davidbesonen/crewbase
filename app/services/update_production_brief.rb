class UpdateProductionBrief
  def initialize(job:, actor:, attributes:, catalog_entry: nil)
    @job, @actor, @attributes, @catalog_entry = job, actor, attributes, catalog_entry
  end

  def call
    @job.transaction do
      if @catalog_entry
        venue = CompanyVenueFromCatalog.new(company: @job.company, entry: @catalog_entry).call
        @attributes = @attributes.except("venue_id", "venue").merge("venue" => venue)
      end
      @job.update!(@attributes)
      SyncJobVenue.new(job: @job).call if @job.saved_change_to_venue_id?
      NotifyProductionCrew.new(job: @job, actor: @actor).call if @job.saved_changes.except("updated_at").any?
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
