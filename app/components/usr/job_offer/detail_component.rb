class Usr::JobOffer::DetailComponent < ApplicationComponent
  def initialize(offer:, owner_view:, recipient_view:, availability:)
    @offer = offer
    @owner_view = owner_view
    @recipient_view = recipient_view
    @availability = availability
    @summary = JobOfferSummary.new(offer:, viewer_id: recipient_view ? offer.profile.user_id : nil)
  end
  def schedule_changed? = @offer.show_itinerary.any? && @offer.work_dates != @offer.job.work_dates.select { |date| date.between?(@offer.starts_at.to_date, @offer.ends_at.to_date) }
end
