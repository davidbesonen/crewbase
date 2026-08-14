require "test_helper"

class CreateUserBillingPortalTest < ActiveSupport::TestCase
  UserRecord = Data.define(:id)
  Subscription = Data.define(:stripe_customer_id)

  test "creates a Stripe customer portal session" do
    session = Data.define(:url).new(url: "https://billing.stripe.com/session")
    gateway = Class.new do
      attr_reader :request
      define_method(:initialize) { |response| @response = response }
      define_method(:create) { |attributes| @request = attributes; @response }
    end.new(session)

    result = CreateUserBillingPortal.new(
      user: UserRecord.new(id: 12),
      subscription: Subscription.new(stripe_customer_id: "cus_crew"),
      return_url: "https://crewbase.test/usr/settings/billing",
      gateway:
    ).call

    assert result.success?
    assert_equal session.url, result.url

    request = gateway.request
    assert_equal "cus_crew", request.fetch(:customer)
    assert_equal "https://crewbase.test/usr/settings/billing", request.fetch(:return_url)
  end

  test "rejects users without a Stripe customer" do
    result = CreateUserBillingPortal.new(
      user: UserRecord.new(id: 12),
      subscription: nil,
      return_url: "https://crewbase.test/usr/settings/billing"
    ).call

    assert_not result.success?
    assert_match(/billing profile/, result.error)
  end
end
