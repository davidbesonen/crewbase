class SyncJobVenue
  def initialize(job:)
    @job = job
  end

  def call
    return unless @job.venue
    venue = @job.venue
    attributes = { address_line_1: venue.address, address_line_2: nil, city: venue.city, state: venue.state,
      country: venue.country, zip_code: venue.postal_code }
    @job.locations = if attributes.values.all?(&:blank?)
      []
    else
      [ Location.find_by(attributes) || Location.create!(attributes) ]
    end
  end
end
