# One source for confirmed offer dates and legacy bookings, for one profile or a
# whole recommendation batch. Values are detached from Active Record instances.
class BookedSchedules
  Schedule = Data.define(:job_id, :starts_at, :ends_at)

  def initialize(profile_ids:)
    @profile_ids = profile_ids.compact.uniq
  end

  def results
    return {} if profile_ids.empty?

    schedules = profile_ids.to_h { |id| [ id, [] ] }
    [ accepted_offers, legacy_applications, legacy_assignments ].each do |rows|
      rows.each do |profile_id, job_id, starts_at, ends_at|
        schedules.fetch(profile_id) << Schedule.new(job_id:, starts_at:, ends_at:)
      end
    end
    schedules.transform_values { |values| values.uniq.freeze }.freeze
  end

  private

  attr_reader :profile_ids

  def accepted_offers
    JobOffer.accepted.where(profile_id: profile_ids).joins(:job_application)
      .pluck(:profile_id, "job_applications.job_id", :starts_at, :ends_at)
  end

  def legacy_applications
    JobApplication.accepted.where(profile_id: profile_ids)
      .where.not(id: JobOffer.accepted.select(:job_application_id))
      .joins(:job).where.not(jobs: { status: [ :completed, :archived ] })
      .pluck(:profile_id, :job_id, "jobs.starts_at", "jobs.ends_at")
  end

  def legacy_assignments
    CrewAssignment.where(profile_id: profile_ids, job_offer_id: nil)
      .joins(crew_position: :job).where.not(jobs: { status: [ :completed, :archived ] })
      .pluck(:profile_id, "jobs.id", "jobs.starts_at", "jobs.ends_at")
  end
end
