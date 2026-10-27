class CompanyVenueFromCatalog
  def initialize(company:, entry:)
    @company, @entry = company, entry
  end

  def call
    @company.with_lock do
      venue = @company.venues.find_or_initialize_by(venue_catalog_entry: @entry)
      venue.assign_attributes(@entry.venue_attributes) if venue.new_record?
      venue.save!
      venue
    end
  end
end
