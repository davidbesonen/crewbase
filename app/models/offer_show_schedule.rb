class OfferShowSchedule
  def initialize(job:, starts_at:, ends_at:)
    @job, @starts_at, @ends_at = job, starts_at, ends_at
  end

  def attributes
    return { work_dates: [], show_itinerary: [] } unless @starts_at && @ends_at
    dates = @job.work_dates.select { |date| date.between?(@starts_at.to_date, @ends_at.to_date) }
    shows = @job.project_shows.chronological.select { |show| show.work_dates.intersect?(dates) }
    { work_dates: dates, show_itinerary: shows.map { |show| show.attributes.slice("name", "city", "state", "venue_name", "starts_on", "ends_on") } }
  end
end
