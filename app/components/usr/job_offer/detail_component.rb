class Usr::JobOffer::DetailComponent < ApplicationComponent
  def initialize(offer:, owner_view:, recipient_view:, availability:)
    @offer = offer
    @owner_view = owner_view
    @recipient_view = recipient_view
    @availability = availability
    @summary = JobOfferSummary.new(offer:, viewer_id: recipient_view ? offer.profile.user_id : nil)
  end
end
