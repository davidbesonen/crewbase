require "test_helper"

class Usr::CompanyBillingControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Company", last_name: "Owner", email: "company-billing-owner@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    industry = Industry.create!(name: "Company Billing Controller")
    @company = Company.create!(name: "Company Billing Controller", contact_email: "billing-controller@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @plan = Plan.create!(key: "billing-controller", name: "Billing Controller", active: true, monthly_price_cents: 1_900, annual_price_cents: 19_000, data: {})
    sign_in @owner, scope: :user
  end

  test "owner starts hosted Checkout" do
    checkout_session = Struct.new(:url).new("https://checkout.stripe.test/company")
    fake_checkout = Object.new
    fake_checkout.define_singleton_method(:call) { checkout_session }

    with_singleton_method(StripeCompanyCheckout, :new, ->(**) { fake_checkout }) do
      post usr_company_billing_checkout_path(@company), params: { plan_id: @plan.id, billing_interval: "monthly" }
    end

    assert_redirected_to checkout_session.url, allow_other_host: true
  end

  test "non-owner cannot start Checkout" do
    outsider = User.create!(first_name: "Billing", last_name: "Viewer", email: "billing-viewer@example.com", password: "password123")
    outsider.profiles.create!(profile_type: "user", completed_at: Time.current)
    outsider.visits.create!
    sign_in outsider, scope: :user

    post usr_company_billing_checkout_path(@company), params: { plan_id: @plan.id, billing_interval: "monthly" }

    assert_response :not_found
  end

  test "owner opens the Stripe customer portal" do
    portal_session = Struct.new(:url).new("https://billing.stripe.test/company")
    fake_portal = Object.new
    fake_portal.define_singleton_method(:call) { portal_session }

    with_singleton_method(StripeCustomerPortal, :new, ->(**) { fake_portal }) do
      post usr_company_billing_portal_path(@company)
    end

    assert_redirected_to portal_session.url, allow_other_host: true
  end

  test "a canceled subscription starts a fresh Checkout instead of a remote update" do
    @company.company_plans.create!(
      plan: @plan,
      status: "canceled",
      stripe_subscription_id: "sub_canceled",
      stripe_subscription_item_id: "si_canceled"
    )
    checkout_session = Struct.new(:url).new("https://checkout.stripe.test/restart")
    fake_checkout = Object.new
    fake_checkout.define_singleton_method(:call) { checkout_session }

    with_singleton_method(StripeCompanyCheckout, :new, ->(**) { fake_checkout }) do
      post usr_company_billing_checkout_path(@company), params: { plan_id: @plan.id, billing_interval: "monthly" }
    end

    assert_redirected_to checkout_session.url, allow_other_host: true
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
