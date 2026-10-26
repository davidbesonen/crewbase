class ProfileJobAvailability
  Result = Data.define(:state, :label, :conflict_dates)

  def initialize(profile:, job:, bookings: nil)
    @profile = profile
    @job = job
    @bookings = bookings
  end

  def result
    conflict_dates = profile.persisted? ? BookingConflicts.new(profile:, schedule: job, bookings: @bookings, excluding_job_id: job.respond_to?(:job_application) ? job.job_application.job_id : job.id).dates : JobAvailability.new(job:).conflict_dates(events:)

    if conflict_dates.any?
      Result.new(
        state: :unavailable,
        label: "Unavailable #{formatted_dates(conflict_dates)}",
        conflict_dates:
      )
    elsif usable_job_dates? && availability_evidence?
      Result.new(state: :no_known_conflict, label: "No known conflict", conflict_dates: [])
    else
      Result.new(state: :unknown, label: "Availability unknown", conflict_dates: [])
    end
  end

  private

  attr_reader :profile, :job

  def events
    @events ||= Array(profile.calendar_events)
  end

  def usable_job_dates?
    job.work_dates.any? || job.starts_at.present?
  end

  def availability_evidence?
    return profile.ical_sync_error.blank? && profile.ical_last_synced_at.present? && profile.ical_last_synced_at >= 24.hours.ago if profile.ical_feed_url.present?

    events.any? { |event| event.provider == "manual" }
  end

  def formatted_dates(dates)
    dates.map { |date| date.strftime("%b %-d") }.to_sentence
  end
end
