require "application_system_test_case"

class CompanyAnalyticsNavigationTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Analytics", last_name: "Owner", email: "metric-browser@example.com", password: "password123")
    @owner.roles << Role.find_or_create_by!(name: "user")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Metric Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @company.company_plans.create!(plan: Plan.create!(PricingCatalog.definitions.last))
    @company.crew_members.create!(first_name: "Private", last_name: "Crew", email: "metric-private@example.com")
    @job = @company.jobs.create!(title: "Published Role", description: "Staffing", is_active: true, status: :published, starts_at: 3.days.from_now, employment_type: :contract, workplace_type: :on_site)
    @company.jobs.create!(title: "Draft Role", status: :draft, employment_type: :contract, workplace_type: :on_site)
    @company.projects.create!(name: "Active Tour", status: :active)
    @company.projects.create!(name: "Completed Tour", status: :completed)
    @application = @job.job_applications.create!(profile: @owner.user_profile, status: :accepted)
    @pending = @job.job_invitations.create!(email: "metric-pending@example.com", invited_by: @owner)
    login_as @owner, scope: :user
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.manage.window.resize_to(1440, 1100)
  end

  test "all six full metric cards open matching views on desktop and mobile in dark mode" do
    visit usr_settings_path
    select "Dark", from: "Appearance"
    [ 1440, 390 ].each do |width|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 1100, deviceScaleFactor: 1, mobile: width == 390)
      visit usr_company_manager_path(@company)
      assert_selector "a[data-company-manager-metric]", count: 6
      assert_selector "[data-company-manager-metric='company_users']", text: "1"
      find("[data-company-manager-metric='company_users']").click
      assert_selector "#company-employees-tab[aria-selected='true']"
      assert_selector "#company-employees.active", text: "1 Company User"
      assert_text "Crew roster contacts are managed separately"
      visit usr_company_manager_path(@company)
      find("[data-company-manager-metric='active_jobs']").click
      assert_text "Published Role"
      assert_no_text "Draft Role"
      visit usr_company_manager_path(@company)
      find("[data-company-manager-metric='active_projects']").click
      assert_text "Active Tour"
      assert_no_text "Completed Tour"
      visit usr_company_manager_path(@company)
      find("[data-company-manager-metric='applications']").click
      assert_selector "h1", text: /Application/
      visit usr_company_manager_path(@company)
      find("[data-company-manager-metric='accepted_hires']").click
      assert_current_path usr_company_applications_path(@company, status: "accepted")
      visit usr_company_manager_path(@company)
      find("[data-company-manager-metric='pending_invitations']").click
      assert_selector "h2", text: "Pending Invitations"
      assert_selector "[data-sent-invitation='#{@pending.id}']"
      assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, width
      visit usr_company_manager_path(@company)
      find("[data-company-manager-metric='company_users']").scroll_to(:center)
      page.save_screenshot("/private/tmp/knowshow-clickable-metrics-#{width}.png")
    end
  ensure
    page.execute_script("localStorage.removeItem('crewbase.theme')") if page.current_url.start_with?("http")
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end
end
