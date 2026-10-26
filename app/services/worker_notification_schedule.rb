class WorkerNotificationSchedule
  def initialize(user:, kind:)
    @user, @kind = user, kind
  end

  def call
    return schedule_reminders if kind == "upcoming_job_reminder"

    profile = user.user_profile
    return unless profile&.completed_at?

    jobs = WorkerJobRecommender.new(profile:, limit: nil).results.map(&:job)
    if kind == "job_alert"
      new_jobs = jobs.select { |job| job.published_at && job.published_at >= 24.hours.ago }.first(5)
      enqueue("job-alerts:#{user.id}:#{Date.current}", job_ids: new_jobs.map(&:id)) if new_jobs.any?
    elsif jobs.any?
      enqueue("recommendations:#{user.id}:#{Date.current.beginning_of_week}", job_ids: jobs.first(5).map(&:id))
    end
  end

  private

  attr_reader :user, :kind

  def schedule_reminders
    bookings = UpcomingBookingReminders.new(user:).call
    bookings.offers.find_each do |offer|
      enqueue("offer-reminder:#{offer.id}:#{offer.starts_at.to_i}", offer_id: offer.id)
    end
    bookings.applications.find_each do |application|
      enqueue("booking-reminder:#{application.id}:#{application.job.starts_at.to_i}", application_id: application.id)
    end
  end

  def enqueue(key, payload)
    NotificationDelivery.enqueue!(recipient: user, kind:, deduplication_key: key, payload:)
  end
end
