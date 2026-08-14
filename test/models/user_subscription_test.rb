require "test_helper"

class UserSubscriptionTest < ActiveSupport::TestCase
  test "only active and trialing subscriptions are entitled" do
    assert UserSubscription.new(status: "active").entitled?
    assert UserSubscription.new(status: "trialing").entitled?
    refute UserSubscription.new(status: "incomplete").entitled?
    refute UserSubscription.new(status: "past_due").entitled?
    refute UserSubscription.new(status: "canceled").entitled?
  end

  test "validates subscription status and billing interval" do
    subscription = UserSubscription.new(status: "unknown", billing_interval: "weekly")

    refute subscription.valid?
    assert_includes subscription.errors[:status], "is not included in the list"
    assert_includes subscription.errors[:billing_interval], "is not included in the list"
  end
end
