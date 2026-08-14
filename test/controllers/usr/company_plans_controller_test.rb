require "test_helper"

class Usr::CompanyPlansControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Plan", last_name: "Owner", email: "plan-owner@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @owner.assignments.create!(role: Role.find_or_create_by!(name: "user"))
    industry = Industry.create!(name: "Plan Controller")
    @company = Company.create!(name: "Plan Controller Company", contact_email: "plan-controller@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @starter = create_plan("starter", 1)
    @team = create_plan("team", 2)
    @studio = create_plan("studio", 3)
    @company.company_plans.create!(plan: @starter, status: "active")
    sign_in @owner, scope: :user
  end

  test "owner can review upgrade options from company navigation" do
    get usr_company_path(@company)

    assert_response :success
    assert_select "[data-company-owner-nav] a[href='#{usr_company_plan_path(@company)}']", text: /Upgrade Plan/

    get usr_company_plan_path(@company)

    assert_response :success
    assert_select "h1", text: /Manage Plan/
    assert_select "[data-current-plan]", text: /Starter/
    assert_select "form[action='#{usr_company_billing_checkout_path(@company)}']", count: 2
  end

  test "selecting a paid upgrade does not activate it before Stripe confirms payment" do
    assert_no_changes -> { CompanyPlanEntitlement.new(@company).current_plan } do
      post usr_company_billing_checkout_path(@company), params: { plan_id: @team.id, billing_interval: "monthly" }
    end

    assert_redirected_to usr_company_plan_path(@company)
  end

  test "non-owner cannot view or change the company plan" do
    outsider = User.create!(first_name: "Plan", last_name: "Viewer", email: "plan-viewer@example.com", password: "password123")
    outsider.profiles.create!(profile_type: "user", completed_at: Time.current)
    outsider.visits.create!
    sign_in outsider, scope: :user

    get usr_company_plan_path(@company)
    assert_response :not_found

    sign_in outsider, scope: :user
    post usr_company_billing_checkout_path(@company), params: { plan_id: @studio.id, billing_interval: "monthly" }
    assert_response :not_found
    assert_equal @starter, CompanyPlanEntitlement.new(@company).current_plan
  end

  private

  def create_plan(key, position)
    Plan.find_or_initialize_by(key:).tap do |plan|
      plan.update!(name: key.titleize, position:, active: true, monthly_price_cents: 1_900 * position, annual_price_cents: 19_000 * position, data: {})
    end
  end
end
