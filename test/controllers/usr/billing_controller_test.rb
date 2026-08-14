require "test_helper"

class Usr::BillingControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "Morgan",
      last_name: "Crew",
      email: "crew-billing@example.com",
      password: "password123"
    )
    @plan = UserPlan.create!(
      name: "Crew Pro",
      slug: "crew-pro",
      monthly_price_cents: 599,
      annual_price_cents: 4_900,
      active: true,
      stripe_monthly_price_id: "price_monthly",
      stripe_annual_price_id: "price_annual",
      data: {
        included: [ "Support Crewbase through its beta" ],
        roadmap: [ "Application insights" ]
      }
    )
    sign_in @user, scope: :user
  end

  test "shows transparent crew pricing without paywalling core features" do
    get usr_settings_billing_path

    assert_response :success
    assert_select "h1", text: "Billing & plans"
    assert_select "[data-user-plan='crew-pro']", text: /\$5\.99/
    assert_select "[data-user-plan='crew-pro']", text: /\$49/
    assert_select "form[action='#{subscription_checkout_usr_settings_billing_path}']", count: 2
    assert_select ".badge", text: "Roadmap — not yet available"
    assert_select "p", text: /profiles, applications, messages, invitations, saved jobs, and availability remain free/i
  end

  test "shows current subscription and Stripe portal management" do
    @user.user_subscriptions.create!(
      user_plan: @plan,
      status: "active",
      billing_interval: "annual",
      stripe_customer_id: "cus_crew",
      stripe_subscription_id: "sub_crew",
      stripe_price_id: "price_annual",
      current_period_end: 1.year.from_now
    )

    get usr_settings_billing_path

    assert_response :success
    assert_select ".badge", text: "Active"
    assert_select "form[action='#{portal_usr_settings_billing_path}'] button", text: "Manage billing in Stripe"
    assert_select "form[action='#{subscription_checkout_usr_settings_billing_path}']", count: 0
  end

  test "checkout reports missing Stripe configuration instead of taking payment" do
    @plan.update!(stripe_monthly_price_id: nil)

    post subscription_checkout_usr_settings_billing_path, params: { user_plan_id: @plan.id, billing_interval: "monthly" }

    assert_redirected_to usr_settings_billing_path
    assert_match(/monthly Stripe price/, flash[:alert])
  end

  test "billing portal requires an existing Stripe subscription" do
    post portal_usr_settings_billing_path

    assert_redirected_to usr_settings_billing_path
    assert_match(/billing profile/, flash[:alert])
  end

  test "billing requires authentication" do
    sign_out @user

    get usr_settings_billing_path

    assert_redirected_to new_user_session_path
  end
end
