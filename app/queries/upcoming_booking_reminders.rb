class UpcomingBookingReminders
  Result = Data.define(:offers, :applications)

  def initialize(user:)
    @user = user
  end

  def call
    window = Time.current..24.hours.from_now
    offers = JobOffer.accepted.where(profile_id: profile_ids, starts_at: window).joins(:job)
      .where.not(jobs: { status: %i[completed archived] })
    applications = JobApplication.accepted.where(profile_id: profile_ids)
      .where.not(id: JobOffer.select(:job_application_id)).joins(:job)
      .where(jobs: { starts_at: window }).where.not(jobs: { status: %i[completed archived] }).includes(:job)
    Result.new(offers:, applications:)
  end

  private

  def profile_ids
    @user.profiles.select(:id)
  end
end
