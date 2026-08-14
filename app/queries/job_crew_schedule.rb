class JobCrewSchedule
  Row = Data.define(:position, :assignment, :profile, :conflict_dates) do
    def conflict?
      conflict_dates.any?
    end

    def availability_label
      return "Available for job dates" unless conflict?
      return "Unavailable on #{conflict_dates.size} job dates" if conflict_dates.size > 3

      "Unavailable #{conflict_dates.map { |date| date.strftime('%b %-d') }.to_sentence}"
    end
  end

  def initialize(job:)
    @job = job
  end

  def rows
    assignments.map do |assignment|
      Row.new(
        position: assignment.crew_position,
        assignment:,
        profile: assignment.profile,
        conflict_dates: conflicts_by_profile.fetch(assignment.profile_id, [])
      )
    end
  end

  private

  attr_reader :job

  def assignments
    @assignments ||= job.crew_assignments.includes(:crew_position, profile: :user).order("crew_positions.id", :id)
  end

  def conflicts_by_profile
    @conflicts_by_profile ||= begin
      return {} if job.starts_at.blank? || job.ends_at.blank?

      events = CalendarEvent
        .where(profile_id: assignments.map(&:profile_id))
        .where("COALESCE(to_date, from_date) >= ? AND COALESCE(from_date, to_date) <= ?", job.starts_at, job.ends_at)

      events.group_by(&:profile_id).transform_values do |profile_events|
        JobAvailability.new(job:).conflict_dates(events: profile_events)
      end
    end
  end
end
