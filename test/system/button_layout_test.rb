require "application_system_test_case"

class ButtonLayoutTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Button", last_name: "Audit", email: "button-audit@example.com", password: "password123")
    @owner.assignments.create!(role: Role.find_or_create_by!(name: "user"))
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Button Audit Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @company.company_plans.create!(plan: Plan.create!(PricingCatalog.definitions.last))
    @company.venues.create!(name: "Main Stage")
    @project = @company.projects.create!(name: "Autumn Tour", project_type: :multi_show)
    @job = @company.jobs.create!(title: "Opening Night", posting_type: :multi_position, status: :draft, employment_type: :contract, workplace_type: :on_site)
    @job.crew_positions.create!(title: "Audio Engineer", headcount: 2)
    login_as @owner, scope: :user
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.manage.window.resize_to(1440, 1100)
  end

  test "venue action has natural height and form buttons align with links" do
    visit usr_company_venues_path(@company)
    add = find_link("Add Venue")
    assert_operator add.rect.height, :<=, 52, "Add Venue must not stretch to the height of its heading and description"
    edit = find_link("Edit")
    remove = find_button("Remove")
    assert_in_delta edit.rect.height, remove.rect.height, 1
    assert_in_delta edit.rect.y, remove.rect.y, 1
    page.save_screenshot("/private/tmp/knowshow-buttons-venues-desktop.png")
  end

  test "workspace button sizes and overflow stay usable across desktop mobile and dark mode" do
    paths = [ usr_dashboards_path, usr_company_path(@company), usr_company_manager_path(@company),
      usr_company_venues_path(@company), usr_company_crew_members_path(@company), usr_company_gig_templates_path(@company),
      usr_project_path(@project), usr_job_crew_path(@job), usr_job_production_path(@job),
      new_usr_company_job_path(@company), usr_profile_path(@owner.user_profile), usr_notifications_path, usr_settings_path, usr_network_path,
      usr_jobs_path, usr_company_projects_path(@company), usr_job_offers_path, usr_job_invitations_path, usr_profiles_path,
      new_usr_company_project_path(@company), new_usr_company_crew_import_path(@company) ]
    [ 1440, 390 ].each do |width|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 1100, deviceScaleFactor: 1, mobile: width == 390)
      paths.each do |path|
        visit path
        assert_no_text "We're sorry, but something went wrong"
        failures = page.evaluate_script(<<~JS)
          Array.from(document.querySelectorAll('.btn:not(.btn-link)')).filter(b => b.getClientRects().length && getComputedStyle(b).visibility !== 'hidden').flatMap(b => {
            const r = b.getBoundingClientRect();
            const errors = [];
            if (r.height > 80) errors.push(`${b.textContent.trim() || b.getAttribute('aria-label')}: stretched height ${r.height}`);
            if (b.classList.contains('btn-icon') && Math.abs(r.width-r.height) > 2) errors.push(`Icon button is not square: ${r.width} x ${r.height}`);
            return errors;
          })
        JS
        assert_empty failures, "#{width}px #{path}: #{failures.join(', ')}"
        assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, width
        if [ usr_dashboards_path, usr_profile_path(@owner.user_profile), new_usr_company_job_path(@company), usr_project_path(@project) ].include?(path)
          page.save_screenshot("/private/tmp/knowshow-buttons-#{width}-#{path.split('/')[2..].join('-')}.png")
        end
        if path == new_usr_company_project_path(@company) && width == 390
          find_button("Create Project & Add Shows").scroll_to(:center)
          page.save_screenshot("/private/tmp/knowshow-buttons-project-actions-mobile.png")
        end
      end
    end
    visit usr_company_venues_path(@company)
    select "Dark", from: "Appearance"
    assert_selector "html[data-bs-theme='dark']"
    page.save_screenshot("/private/tmp/knowshow-buttons-venues-mobile-dark.png")
  ensure
    page.execute_script("localStorage.removeItem('crewbase.theme')")
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end

  test "public account and admin buttons remain aligned and usable" do
    @owner.roles << Role.find_or_create_by!(name: "app_owner")
    [ 1440, 390 ].each do |width|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 1100, deviceScaleFactor: 1, mobile: width == 390)
      [ admin_root_path, admin_users_path, admin_user_path(@owner), welcome_path ].each do |path|
        visit path
        assert_selector "h1"
        assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, width
        page.save_screenshot("/private/tmp/knowshow-buttons-#{width}-#{path.delete_prefix('/').tr('/', '-')}.png")
      end
    end
    logout :user
    visit new_user_session_path
    assert_selector "form.button_to > .btn.w-100"
    assert_in_delta find("form.button_to").rect.width, find("input[type='email']").rect.width, 2
    page.save_screenshot("/private/tmp/knowshow-buttons-login-mobile.png")
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end
end
