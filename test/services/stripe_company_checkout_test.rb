require "test_helper"

class StripeCompanyCheckoutTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Billing", last_name: "Owner", email: "billing-owner@example.com", password: "password123")
    industry = Industry.create!(name: "Billing Checkout")
    @company = Company.create!(name: "Billing Checkout Company", contact_email: "billing@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @plan = Plan.create!(
      key: "billing-team",
      name: "Billing Team",
      active: true,
      position: 10,
      monthly_price_cents: 4_900,
      annual_price_cents: 49_000,
      data: {}
    )
  end

  test "creates a hosted subscription Checkout Session from a server-side price mapping" do
    session = Struct.new(:url).new("https://checkout.stripe.test/session")
    request = nil
    fake_sessions = Object.new
    fake_sessions.define_singleton_method(:create) do |parameters, request_options = {}|
      request = [ parameters, request_options ]
      session
    end

    with_singleton_method(Stripe::Checkout::Session, :create, ->(*arguments) { fake_sessions.create(*arguments) }) do
      result = StripeCompanyCheckout.new(
        company: @company,
        owner: @owner,
        plan: @plan,
        interval: "monthly",
        success_url: "https://crewbase.test/success?session_id={CHECKOUT_SESSION_ID}",
        cancel_url: "https://crewbase.test/cancel",
        price_catalog: { [ @plan.key, "monthly" ] => "price_team_monthly" }
      ).call

      assert_equal session, result
    end

    parameters, request_options = request
    assert_equal "subscription", parameters[:mode]
    assert_equal [ { price: "price_team_monthly", quantity: 1 } ], parameters[:line_items]
    assert_equal @owner.email, parameters[:customer_email]
    assert_equal @company.id.to_s, parameters[:client_reference_id]
    assert_equal({ "company_id" => @company.id.to_s, "plan_id" => @plan.id.to_s, "billing_interval" => "monthly" }, parameters[:metadata])
    assert_equal parameters[:metadata], parameters.dig(:subscription_data, :metadata)
    assert request_options[:idempotency_key].present?
  end

  test "rejects an inactive plan before contacting Stripe" do
    @plan.update!(active: false)

    error = assert_raises(StripeCompanyCheckout::InvalidSelection) do
      StripeCompanyCheckout.new(
        company: @company,
        owner: @owner,
        plan: @plan,
        interval: "monthly",
        success_url: "https://crewbase.test/success",
        cancel_url: "https://crewbase.test/cancel",
        price_catalog: {}
      ).call
    end

    assert_equal "That billing plan is unavailable.", error.message
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
