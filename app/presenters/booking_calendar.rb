class BookingCalendar
  def initialize(offer:, url:)
    @offer, @url = offer, url
  end

  def to_ical
    calendar = Icalendar::Calendar.new
    calendar.prodid = "-//Crewbase//Confirmed booking//EN"
    calendar.event do |event|
      event.uid = "booking-#{@offer.id}@crewbase"
      event.dtstamp = @offer.updated_at.utc
      event.dtstart = Icalendar::Values::DateTime.new(@offer.starts_at.utc, "tzid" => "UTC")
      event.dtend = Icalendar::Values::DateTime.new(@offer.ends_at.utc, "tzid" => "UTC")
      event.summary = "#{@offer.role} — #{@offer.job_application.job.company.name}"
      event.location = @offer.job_application.job.formatted_location
      event.description = "Confirmed Crewbase booking. View the latest details: #{@url}\nThis is a calendar snapshot; later changes do not sync automatically."
      event.url = @url
      event.status = "CONFIRMED"
      event.ip_class = "PRIVATE"
    end
    calendar.to_ical
  end
end
