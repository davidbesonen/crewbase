require "test_helper"

class Usr::CompanyManagersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Team", last_name: "Owner", email: "team-owner@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @owner.assignments.create!(role: Role.find_or_create_by!(name: "user"))
    industry = Industry.create!(name: "Live Production")
    @company = Company.create!(name: "Team Company", contact_email: "team@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    plan = Plan.create!(name: "Team", key: "team", monthly_price_cents: 4_900, annual_price_cents: 49_000, active: true, position: 2)
    @company.company_plans.create!(plan:)
  end

  test "Team owner can open the company manager dashboard" do
    sign_in @owner, scope: :user

    get usr_company_manager_path(@company)

    assert_response :success
    assert_select "[data-company-owner-nav]", count: 1 do
      assert_select "a[href='#{usr_company_manager_path(@company)}'][aria-current='page']", text: /Manager/
      assert_select "a[href='#{new_usr_company_job_placement_path(@company)}']", text: /Post a Job/
      assert_select "a[href='#{usr_company_projects_path(@company)}']", text: /Projects/
    end
    assert_select "h1", text: /Company Manager/
    assert_select "[data-company-manager-metric]", minimum: 6
    assert_select "[data-studio-benefit]", count: 0
    assert_select ".card", text: /Next Steps/
    assert_select "canvas[data-controller='admin-chart']", count: 1
  end

  test "free owners can use manager tools without accessing analytics" do
    @company.company_plans.delete_all
    sign_in @owner, scope: :user

    get usr_company_manager_path(@company)

    assert_response :success
    assert_select "[data-company-management-tools]" do
      assert_select "a[href='#{usr_company_path(@company)}']", text: /Company Profile/
      assert_select "a[href='#{edit_usr_company_path(@company)}']", text: /Edit Company/
      assert_select "a[href='#{usr_company_gig_templates_path(@company)}']", text: /Templates/
      assert_select "a[href='#{usr_company_venues_path(@company)}']", text: /Venues/
      assert_select "a[href='#{usr_company_plan_path(@company)}']", text: /Plan & Billing/
    end
    assert_select "[data-crew-roster-upload]"
    assert_select "[data-company-manager-metric]", count: 0
    assert_select "canvas[data-controller='admin-chart']", count: 0
    assert_select "[data-analytics-upgrade]"
  end

  test "Studio owner can open the company manager dashboard with actionable next steps" do
    studio = Plan.create!(name: "Studio", key: "studio", monthly_price_cents: 9_900, annual_price_cents: 99_000, active: true, position: 3)
    @company.company_plans.create!(plan: studio)
    sign_in @owner, scope: :user

    get usr_company_manager_path(@company)

    assert_response :success
    assert_select "[data-studio-benefit]", count: 0
    assert_select "a[href='#{usr_company_applications_path(@company)}']", text: "Review applications"
  end

  test "non-owner cannot open the company manager dashboard" do
    outsider = User.create!(first_name: "Other", last_name: "User", email: "other-manager@example.com", password: "password123")
    outsider.profiles.create!(profile_type: "user", completed_at: Time.current)
    outsider.visits.create!
    sign_in outsider, scope: :user

    get usr_company_manager_path(@company)

    assert_response :not_found
  end

  test "company page gives owners a workspace navigation card" do
    sign_in @owner, scope: :user

    get usr_company_path(@company)

    assert_response :success
    assert_select "[data-company-owner-nav]", count: 1 do
      assert_select "a[href='#{usr_company_manager_path(@company)}']", text: /Manager/
      assert_select "a[href='#{new_usr_company_job_placement_path(@company)}']", text: /Post a Job/
      assert_select "a[href='#{usr_company_projects_path(@company)}']", text: /Projects/
    end
    assert_select ".app-hero a[href='#{usr_company_manager_path(@company)}']", count: 0
    assert_select ".user-sidenav-card a[href='#{usr_company_manager_path(@company)}']", count: 0
  end

  test "company page hides workspace navigation from non-owners" do
    viewer = User.create!(first_name: "Public", last_name: "Viewer", email: "company-viewer@example.com", password: "password123")
    viewer.profiles.create!(profile_type: "user", completed_at: Time.current)
    viewer.visits.create!
    viewer.assignments.create!(role: Role.find_or_create_by!(name: "user"))
    @company.update!(is_public: true)
    sign_in viewer, scope: :user

    get usr_company_path(@company)

    assert_response :success
    assert_select "[data-company-owner-nav]", count: 0
  end
end
