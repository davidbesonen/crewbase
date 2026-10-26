class NotificationEmailContent
  attr_reader :delivery, :jobs, :offer, :application

  def initialize(delivery:)
    @delivery = delivery
    @jobs = []
    prepare
  end

  def available?
    jobs.any? || offer.present? || application.present?
  end

  def title
    {
      "job_alert" => "A new job matches your experience",
      "recommended_role" => "Your weekly Crewbase recommendations",
      "upcoming_job_reminder" => "Your booking starts soon",
      "job_offer" => "You have a new job offer"
    }.fetch(delivery.kind)
  end

  private

  def prepare
    case delivery.kind
    when "job_alert", "recommended_role"
      profile = delivery.recipient.user_profile
      return unless profile&.completed_at?

      @jobs = WorkerJobRecommender.new(profile:, jobs: Job.where(id: delivery.payload["job_ids"]), limit: 5).results.map(&:job)
    when "job_offer"
      @offer = JobOffer.pending.where(profile_id: delivery.recipient.profiles.select(:id)).find_by(id: delivery.payload["offer_id"])
      @offer = nil if offer&.expires_at && offer.expires_at <= Time.current
    when "upcoming_job_reminder"
      prepare_booking
    end
  end

  def prepare_booking
    bookings = UpcomingBookingReminders.new(user: delivery.recipient).call
    @offer = bookings.offers.find_by(id: delivery.payload["offer_id"])
    @application = bookings.applications.find_by(id: delivery.payload["application_id"]) unless offer
  end
end
