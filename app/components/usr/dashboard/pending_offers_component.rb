class Usr::Dashboard::PendingOffersComponent < ApplicationComponent
  def initialize(offers:, count:)
    @offers, @count = offers, count
  end

  def render?
    @offers.any?
  end
end
