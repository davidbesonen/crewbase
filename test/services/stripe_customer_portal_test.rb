require "test_helper"

class StripeCustomerPortalTest < ActiveSupport::TestCase
  test "creates a short-lived portal session for the company's Stripe customer" do
    company = Struct.new(:stripe_customer_id).new("cus_company")
    portal_session = Struct.new(:url).new("https://billing.stripe.test/session")
    parameters = nil

    with_singleton_method(Stripe::BillingPortal::Session, :create, ->(value) { parameters = value; portal_session }) do
      result = StripeCustomerPortal.new(company:, return_url: "https://crewbase.test/company").call

      assert_equal portal_session, result
    end

    assert_equal({ customer: "cus_company", return_url: "https://crewbase.test/company" }, parameters)
  end

  test "requires a Stripe customer" do
    company = Struct.new(:stripe_customer_id).new(nil)

    assert_raises(StripeCustomerPortal::CustomerMissing) do
      StripeCustomerPortal.new(company:, return_url: "https://crewbase.test/company").call
    end
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
