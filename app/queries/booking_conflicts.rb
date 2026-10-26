class BookingConflicts
  def initialize(profile:, schedule:, excluding_job_id: nil, bookings: nil)
    @profile, @schedule, @excluding_job_id, @bookings = profile, schedule, excluding_job_id, bookings
  end

  def dates
    calendar_dates = JobAvailability.new(job: schedule).conflict_dates(events: profile.calendar_events)
    booked_dates = bookings.flat_map do |booking|
      next [] if booking.job_id == excluding_job_id || booking.starts_at.nil?

      event = CalendarEvent.new(event_type: "blockout", from_date: booking.starts_at.to_date, to_date: (booking.ends_at || booking.starts_at).to_date)
      JobAvailability.new(job: schedule).conflict_dates(events: [ event ])
    end
    (calendar_dates + booked_dates).uniq.sort
  end

  private

  attr_reader :profile, :schedule, :excluding_job_id

  def bookings
    @bookings ||= BookedSchedules.new(profile_ids: [ profile.id ]).results.fetch(profile.id, [])
  end
end
