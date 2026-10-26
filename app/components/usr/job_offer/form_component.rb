class Usr::JobOffer::FormComponent < ApplicationComponent
  def initialize(offer:, application:, position:, positions:)
    @offer = offer
    @application = application
    @position = position
    @positions = positions
  end

  def currency_prefix
    return "$" if @offer.currency == "USD"

    @offer.currency.presence || "—"
  end
end
