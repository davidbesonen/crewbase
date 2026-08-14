require "test_helper"

class StripeEventTest < ActiveSupport::TestCase
  test "requires a unique Stripe event identifier" do
    StripeEvent.create!(stripe_event_id: "evt_unique", event_type: "customer.subscription.updated", payload: {})
    duplicate = StripeEvent.new(stripe_event_id: "evt_unique", event_type: "invoice.paid", payload: {})

    refute duplicate.valid?
    assert_includes duplicate.errors[:stripe_event_id], "has already been taken"
  end
end
