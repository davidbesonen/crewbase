class Usr::CrewBillingComponent < ApplicationComponent
  def initialize(subscription:)
    @subscription = subscription
  end

  private

  attr_reader :subscription

  def subscription_status
    subscription.status.humanize
  end
end
