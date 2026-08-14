require "test_helper"

class CreateUserSubscriptionCheckoutTest < ActiveSupport::TestCase
  Plan = Data.define(:id, :name, :stripe_monthly_price_id, :stripe_annual_price_id)
  UserRecord = Data.define(:id, :email)

  test "creates a hosted subscription checkout for the requested billing interval" do
    plan = Plan.new(id: 9, name: "Crewbase Pro", stripe_monthly_price_id: "price_pro_monthly", stripe_annual_price_id: "price_pro_annual")
    user = UserRecord.new(id: 12, email: "crew@example.com")
    session = Data.define(:url).new(url: "https://checkout.stripe.com/session")
    gateway = Class.new do
      attr_reader :request
      define_method(:initialize) { |response| @response = response }
      define_method(:create) { |attributes| @request = attributes; @response }
    end.new(session)

    result = CreateUserSubscriptionCheckout.new(
      user:,
      plan:,
      billing_interval: "annual",
      success_url: "https://crewbase.test/usr/settings/billing?checkout=success",
      cancel_url: "https://crewbase.test/usr/settings/billing",
      stripe_customer_id: "cus_crew",
      gateway:
    ).call

    assert result.success?
    assert_equal session.url, result.url

    request = gateway.request
    assert_equal "subscription", request.fetch(:mode)
    assert_equal "cus_crew", request.fetch(:customer)
    assert_equal [ { price: "price_pro_annual", quantity: 1 } ], request.fetch(:line_items)
    assert_equal({ "user_id" => "12", "user_plan_id" => "9", "billing_interval" => "annual" }, request.fetch(:metadata))
    assert_equal request.fetch(:metadata), request.dig(:subscription_data, :metadata)
  end

  test "rejects checkout when the Stripe price has not been configured" do
    plan = Plan.new(id: 9, name: "Crewbase Pro", stripe_monthly_price_id: nil, stripe_annual_price_id: nil)
    user = UserRecord.new(id: 12, email: "crew@example.com")

    result = CreateUserSubscriptionCheckout.new(
      user:,
      plan:,
      billing_interval: "monthly",
      success_url: "https://crewbase.test/success",
      cancel_url: "https://crewbase.test/cancel"
    ).call

    assert_not result.success?
    assert_match(/monthly Stripe price/, result.error)
  end

  test "rejects unsupported billing intervals" do
    result = CreateUserSubscriptionCheckout.new(
      user: UserRecord.new(id: 12, email: "crew@example.com"),
      plan: Plan.new(id: 9, name: "Crewbase Pro", stripe_monthly_price_id: nil, stripe_annual_price_id: nil),
      billing_interval: "weekly",
      success_url: "https://crewbase.test/success",
      cancel_url: "https://crewbase.test/cancel"
    ).call

    assert_not result.success?
    assert_equal "Choose monthly or annual billing.", result.error
  end
end
