class Usr::CrewBillingComponent < ApplicationComponent
  def initialize(plans:, subscription:)
    @plans = plans
    @subscription = subscription
  end

  private

  attr_reader :plans, :subscription

  def money(cents)
    helpers.number_to_currency(cents / 100.0, precision: cents % 100 == 0 ? 0 : 2)
  end

  def subscription_status
    subscription.status.humanize
  end
end
