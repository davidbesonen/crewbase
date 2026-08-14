require "test_helper"

class StripeCompanySubscriptionChangeTest < ActiveSupport::TestCase
  test "updates the existing item with immediate proration and payment safety" do
    company_plan = Struct.new(:stripe_subscription_id, :stripe_subscription_item_id).new("sub_company", "si_company")
    request = nil

    replacement = lambda do |subscription_id, parameters, options|
      request = [ subscription_id, parameters, options ]
      Struct.new(:id).new(subscription_id)
    end

    with_singleton_method(Stripe::Subscription, :update, replacement) do
      StripeCompanySubscriptionChange.new(company_plan:, stripe_price_id: "price_studio").call
    end

    subscription_id, parameters, options = request
    assert_equal "sub_company", subscription_id
    assert_equal [ { id: "si_company", price: "price_studio" } ], parameters[:items]
    assert_equal "always_invoice", parameters[:proration_behavior]
    assert_equal "pending_if_incomplete", parameters[:payment_behavior]
    assert options[:idempotency_key].present?
  end

  private

  def with_singleton_method(target, method_name, replacement)
    singleton = target.singleton_class
    original = singleton.instance_method(method_name)
    singleton.define_method(method_name, replacement)
    yield
  ensure
    singleton.define_method(method_name, original)
  end
end
