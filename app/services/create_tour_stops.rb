class CreateTourStops
  class InvalidStop < StandardError; end
  Result = Data.define(:success?, :jobs, :error)

  def initialize(project:, source:, actor:, stops:)
    @project, @source, @actor, @stops = project, source, actor, stops
  end

  def call
    return failure("Choose a gig or template to reuse. Your stops have been kept below.") unless @source
    return failure("Choose a setup from this company.") unless @source.company_id == @project.company_id && @project.company.is_owner?(@actor)
    return failure("Add between 1 and 50 tour stops.") unless @stops.size.between?(1, 50)
    jobs = Job.transaction do
      @stops.each_with_index.map do |stop, index|
        raise InvalidStop, "Stop #{index + 1}: add a title and start date." if stop["title"].blank? || stop["starts_on"].blank?
        venue = @project.company.venues.find(stop["venue_id"]) if stop["venue_id"].present?
        if stop["venue_catalog_entry_id"].present?
          entry = VenueCatalogEntry.find(stop["venue_catalog_entry_id"])
          venue = CompanyVenueFromCatalog.new(company: @project.company, entry:).call
        end
        result = ReuseGig.new(source: @source, actor: @actor, project: @project, venue:,
          title: stop["title"], starts_on: stop["starts_on"]).call
        raise InvalidStop, "Stop #{index + 1}: #{result.error}" unless result.success?
        result.job.update!(audience: :invite_only)
        result.job
      end
    end
    Result.new(success?: true, jobs:, error: nil)
  rescue InvalidStop, ActiveRecord::RecordInvalid => error
    failure(error.message)
  end

  private

  def failure(error) = Result.new(success?: false, jobs: [], error:)
end
