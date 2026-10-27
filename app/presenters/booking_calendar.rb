class BookingCalendar
  def initialize(offer:, url:)
    @offer, @url = offer, url
  end

  def to_ical
    calendar = Icalendar::Calendar.new
    calendar.prodid = "-//KnowShow//Confirmed booking//EN"
    dates = @offer.work_dates.presence || [ nil ]
    dates.each do |date|
      calendar.event do |event|
        # Keep the stable UID so existing calendar imports do not duplicate after rebranding.
        event.uid = "booking-#{@offer.id}#{"-#{date.iso8601}" if date}@crewbase"
        event.dtstamp = @offer.updated_at.utc
        if date
          event.dtstart = Icalendar::Values::Date.new(date)
          event.dtend = Icalendar::Values::Date.new(date + 1)
        else
          event.dtstart = Icalendar::Values::DateTime.new(@offer.starts_at.utc, "tzid" => "UTC")
          event.dtend = Icalendar::Values::DateTime.new(@offer.ends_at.utc, "tzid" => "UTC")
        end
        event.summary = "#{@offer.role} — #{@offer.job_application.job.company.name}"
        event.location = @offer.show_itinerary.any? ? @offer.show_itinerary.map { |show| [ show["city"], show["state"] ].compact_blank.join(", ") }.uniq.join(" / ") : @offer.job_application.job.formatted_location
        event.description = "Confirmed KnowShow booking. View the latest details: #{@url}\nThis is a calendar snapshot; later changes do not sync automatically."
        event.url = @url
        event.status = "CONFIRMED"
        event.ip_class = "PRIVATE"
      end
    end
    calendar.to_ical
  end
end
