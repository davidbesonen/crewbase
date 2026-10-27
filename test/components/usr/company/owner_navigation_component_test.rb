require "test_helper"

class Usr::Company::OwnerNavigationComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @company = companies(:one)
    plan = Plan.create!(name: "Workspace Team", key: "team", monthly_price_cents: 4_900, annual_price_cents: 49_000)
    @company.company_plans.create!(plan: plan)
  end

  test "workspace destinations mark the current page without competing with primary actions" do
    destinations = {
      profile: usr_company_path(@company),
      manager: usr_company_manager_path(@company),
      post_job: new_usr_company_job_placement_path(@company),
      projects: usr_company_projects_path(@company),
      edit: edit_usr_company_path(@company),
      staffing: usr_company_staffing_path(@company),
      roster: usr_company_crew_members_path(@company),
      templates: usr_company_gig_templates_path(@company),
      venues: usr_company_venues_path(@company),
      plan: usr_company_plan_path(@company)
    }

    destinations.each do |active, path|
      render_inline(
        Usr::Company::OwnerNavigationComponent.new(
          company: @company, active: active, entitlement: CompanyPlanEntitlement.new(@company)
        )
      )

      assert_selector "nav[aria-label='Company workspace']"
      assert_selector "a[aria-current='page']", count: 1
      assert_selector "a.btn-quiet[aria-current='page'][href='#{path}']"
      assert_no_selector "a.btn-primary"
      assert_selector "select[aria-label='Company workspace destination'] option[selected][value='#{path}']", visible: :all
    end
  end

  test "unavailable manager remains disabled" do
    @company.company_plans.delete_all
    render_inline(
      Usr::Company::OwnerNavigationComponent.new(
        company: @company, active: :profile, entitlement: CompanyPlanEntitlement.new(@company)
      )
    )

    assert_selector "[data-feature-upgrade='staffing-analytics'][aria-disabled='true']"
    assert_no_selector "a[href='#{usr_company_manager_path(@company)}']"
  end
end
