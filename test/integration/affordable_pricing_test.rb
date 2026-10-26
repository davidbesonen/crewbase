require "test_helper"

class AffordablePricingTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Pricing", last_name: "Owner", email: "pricing@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @industry = Industry.create!(name: "Pricing industry")
    sign_in @owner
  end

  test "free company setup activates access without checkout or a payment step" do
    free = Plan.create!(key: "free", name: "Starter", active: true, monthly_price_cents: 0, annual_price_cents: 0,
      data: { seats_limit: 2, active_jobs_limit: 2, projects_limit: 1 })
    get new_usr_company_path(current_page: "company_details_form", plan_id: free.id)
    assert_response :success
    assert_not_includes response.body, "Continue to Payment"
    assert_not_includes response.body, "company_billing_monthly"
    assert_select "details:not([open]) summary", text: "Website & social links (optional)"

    post usr_companies_path, params: { plan_id: free.id, company: { name: "Free Company", contact_email: "free@example.com", industry_ids: [ @industry.id ] } }
    company = @owner.owned_companies.find_by!(name: "Free Company")
    assert_redirected_to usr_company_path(company)
    assert_equal free, CompanyPlanEntitlement.new(company).current_plan
    assert_nil company.company_plans.last.current_period_end
    get usr_company_applications_path(company)
    assert_response :success
    assert CompanyPlanEntitlement.new(company).allowed?(:multi_position_gigs)
  end

  test "company without a selected plan starts free instead of bypassing limits" do
    free = Plan.create!(key: "free", name: "Starter", active: true, monthly_price_cents: 0, annual_price_cents: 0)
    post usr_companies_path, params: { company: { name: "Default Company", contact_email: "default@example.com", industry_ids: [ @industry.id ] } }
    company = @owner.owned_companies.find_by!(name: "Default Company")
    assert_equal free, CompanyPlanEntitlement.new(company).current_plan
  end

  test "an unconfigured paid plan explains availability without a broken checkout button" do
    free = Plan.create!(key: "free", name: "Starter", active: true, monthly_price_cents: 0, annual_price_cents: 0)
    Plan.create!(key: "team_2026", name: "Team", active: true, monthly_price_cents: 1900, annual_price_cents: 19000)
    company = Company.create!(name: "Free Owner", contact_email: "owner@example.com", industries: [ @industry ])
    company.company_assignments.create!(user: @owner, role: "owner")
    company.company_plans.create!(plan: free, status: "active")
    get usr_company_plan_path(company)
    assert_response :success
    assert_select "form[action='#{usr_company_billing_checkout_path(company)}']", count: 0
    assert_select "p", text: /Paid upgrades are not available yet/
    assert_select "[data-current-plan]", text: /Free/
  end

  test "crew billing explains free access without selling a roadmap" do
    get usr_settings_billing_path
    assert_response :success
    assert_select "h2", text: "Free for crew"
    assert_select "form[action='#{subscription_checkout_usr_settings_billing_path}']", count: 0
    assert_select "a[href='#{usr_jobs_path}']", text: /Find work/
    assert_not_includes response.body, "Roadmap"
  end
  test "new company flow shows the chosen paid price and billing options" do
    plan = Plan.create!(key: "team_2026", name: "Team", active: true, monthly_price_cents: 1900, annual_price_cents: 19000, stripe_monthly_price_id: "price_team", stripe_annual_price_id: "price_team_year")
    get new_usr_company_path(current_page: "company_details_form", plan_id: plan.id)
    assert_select "input[name='plan_id'][value='#{plan.id}']"
    assert_select "label[for='company_billing_monthly']", text: "$19/month"
    assert_select "label[for='company_billing_annual']", text: "$190/year"
    assert_select "input[type='submit'][value='Create Company and Continue to Payment']"
  end

  test "company signup only offers configured billing intervals" do
    plan = Plan.create!(key: "team_2026", name: "Team", active: true, monthly_price_cents: 1900, annual_price_cents: 19000, stripe_annual_price_id: "price_team_year")
    get new_usr_company_path(current_page: "company_details_form", plan_id: plan.id)
    assert_select "input#company_billing_monthly", count: 0
    assert_select "input#company_billing_annual[checked]", count: 1
  end

  test "canceled paid companies retain free access without reviving a paid subscription" do
    free = Plan.create!(key: "free", name: "Starter", active: true, monthly_price_cents: 0, annual_price_cents: 0)
    paid = Plan.create!(key: "team_2026", name: "Team", active: true, monthly_price_cents: 1900, annual_price_cents: 19000)
    company = Company.create!(name: "Canceled Owner", contact_email: "cancel@example.com", industries: [ @industry ])
    company.company_assignments.create!(user: @owner, role: "owner")
    subscription = company.company_plans.create!(plan: paid, status: "canceled")
    assert_equal free, CompanyPlanEntitlement.new(company).current_plan
    assert_equal "canceled", subscription.reload.status
  end
end
