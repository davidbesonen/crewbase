require "application_system_test_case"

class DarkAppearanceAuditTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Appearance", last_name: "Owner", email: "appearance-audit@example.com", password: "password123")
    @owner.roles << Role.find_or_create_by!(name: "app_owner")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Night Show Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @company.company_plans.create!(plan: Plan.create!(PricingCatalog.definitions.last))
    @company.crew_members.create!(first_name: "Casey", last_name: "Lighting", email: "casey@example.com", city: "Nashville")
    @batch = @company.crew_imports.create!(uploaded_by: @owner, rows: [ { "first_name" => "Casey", "last_name" => "Lighting", "email" => "casey@example.com" } ])
    @free_company = Company.create!(name: "New Show Company", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @free_company.company_assignments.create!(user: @owner, role: "owner")
    @free_company.company_plans.create!(plan: Plan.create!(PricingCatalog.definitions.first))
    @project = @company.projects.create!(name: "Night Tour", project_type: :multi_show)
    @job = @company.jobs.create!(title: "Lighting Crew", status: :draft, employment_type: :contract, workplace_type: :on_site)
    @project.project_shows.create!(city: "Nashville", starts_on: Date.current + 14)
    @application = @job.job_applications.create!(profile: @owner.user_profile)
    @conversation = Conversation.create!(context: @application)
    @conversation.memberships.create!(user: @owner)
    login_as @owner, scope: :user
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.manage.window.resize_to(1440, 1100)
  end

  test "appearance lives in settings and dashboard search has one continuous dark surface" do
    visit usr_dashboards_path
    assert_no_selector "[data-theme-choice]"
    visit usr_settings_path
    within "[data-appearance-preferences]" do
      select "Dark", from: "Appearance"
    end
    assert_selector "html[data-bs-theme='dark']"
    visit usr_dashboards_path
    assert_no_selector "[data-theme-choice]"
    assert_equal "rgba(0, 0, 0, 0)", page.evaluate_script("getComputedStyle(document.querySelector('.dashboard-search-field input')).backgroundColor")
    find(".dashboard-search-field input").click
    assert_equal "rgba(0, 0, 0, 0)", page.evaluate_script("getComputedStyle(document.querySelector('.dashboard-search-field input')).backgroundColor")
    find(".dashboard-search-field input").set("Night Show")
    assert_selector "#dashboard-quick-search-results [role='option']", text: @company.name
    assert_equal "rgb(17, 24, 39)", page.evaluate_script("getComputedStyle(document.querySelector('#dashboard-quick-search-results')).backgroundColor")
    find(".dashboard-search-field input").send_keys(:arrow_down)
    assert_selector "#dashboard-quick-search-results .active"
    assert_selector "#dashboard-quick-search-results .active" do |result|
      result.evaluate_script("getComputedStyle(this).backgroundColor") == "rgb(27, 37, 55)"
    end
    page.save_screenshot("/private/tmp/knowshow-dark-dashboard.png")
    page.refresh
    assert_selector "html[data-bs-theme='dark']"
  end

  test "dark surfaces remain consistent across company crew forms messages and admin on desktop and mobile" do
    visit usr_settings_path
    select "Dark", from: "Appearance"
    paths = [
      usr_dashboards_path, usr_settings_path, usr_settings_billing_path, usr_profile_path(@owner.user_profile),
      usr_company_path(@company), usr_company_manager_path(@company), usr_company_venues_path(@company),
      usr_company_crew_members_path(@company), usr_company_staffing_path(@company), usr_company_gig_templates_path(@company),
      usr_company_projects_path(@company), usr_project_path(@project), new_usr_company_job_path(@company),
      new_usr_company_project_path(@company), new_usr_company_crew_import_path(@company), usr_job_production_path(@job),
      usr_jobs_path, usr_profiles_path, usr_network_path, usr_conversations_path, usr_notifications_path,
      usr_company_applications_path(@company), usr_job_offers_path, admin_root_path, admin_users_path,
      usr_company_crew_import_path(@company, @batch), new_usr_company_venue_path(@company),
      usr_company_plan_path(@free_company), usr_conversation_path(@conversation), admin_user_path(@owner),
      edit_usr_profile_path(@owner.user_profile)
    ]
    findings = []
    contrast_findings = []
    [ 1440, 390 ].each do |width|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 1100, deviceScaleFactor: 1, mobile: width == 390)
      paths.each do |path|
        visit path
        assert_selector "html[data-bs-theme='dark']"
        assert_no_text "We're sorry, but something went wrong"
        assert_no_selector ".navbar [data-theme-choice]"
        assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, width
        bright_surfaces = page.evaluate_script(<<~JS)
          Array.from(document.querySelectorAll('.app-content *')).filter(el => {
            const r = el.getBoundingClientRect();
            return r.width > 32 && r.height > 18 && getComputedStyle(el).visibility !== 'hidden';
          }).flatMap(el => {
            const color = getComputedStyle(el).backgroundColor.match(/[\\d.]+/g)?.map(Number);
            if (!color || (color.length === 4 && color[3] < .5) || Math.min(...color.slice(0,3)) < 200) return [];
            return [el.tagName + '.' + el.className + ': ' + getComputedStyle(el).backgroundColor];
          })
        JS
        contrast = page.evaluate_script(<<~JS)
          (() => {
            const rgb = value => value.match(/[\\d.]+/g)?.map(Number);
            const lum = c => c.slice(0,3).map(v => v/255).map(v => v <= .04045 ? v/12.92 : ((v+.055)/1.055)**2.4).reduce((a,v,i) => a + v * [.2126,.7152,.0722][i],0);
            return Array.from(document.querySelectorAll('.app-content a, .app-content p, .app-content label, .app-content span, .app-content h2, .app-content th, .app-content button')).flatMap(el => {
              if (!el.getClientRects().length || !el.textContent.trim() || el.children.length || el.closest('[disabled], .disabled')) return [];
              const fg = rgb(getComputedStyle(el).color);
              let node = el, bg;
              while(node) {
                const style = getComputedStyle(node);
                if (style.backgroundImage !== 'none') return [];
                bg = rgb(style.backgroundColor);
                if (bg && (bg.length === 3 || bg[3] > .95)) break;
                node = node.parentElement;
              }
              if (!fg || !bg || !node) return [];
              const ratio = (Math.max(lum(fg), lum(bg))+.05)/(Math.min(lum(fg), lum(bg))+.05);
              return ratio < 4.5 ? [el.tagName + '.' + el.className + ': ' + el.textContent.trim().slice(0,60) + ' contrast ' + ratio.toFixed(2)] : [];
            });
          })()
        JS
        contrast_findings.concat(contrast.map { |finding| "#{width} #{path}: #{finding}" })
        findings.concat(bright_surfaces.map { |surface| "#{width} #{path}: #{surface}" })
        if [ usr_dashboards_path, usr_company_manager_path(@company), usr_settings_path, new_usr_company_job_path(@company), usr_project_path(@project) ].include?(path)
          page.save_screenshot("/private/tmp/knowshow-dark-audit-#{width}-#{path.delete_prefix('/').tr('/', '-')}.png")
        end
      end
    end
    File.write("/private/tmp/knowshow-dark-contrast-findings.txt", contrast_findings.uniq.join("\n"))
    File.write("/private/tmp/knowshow-dark-audit-findings.txt", findings.uniq.join("\n"))
    assert_empty contrast_findings, "Low text contrast: #{contrast_findings.join('; ')}"
    assert_empty findings, "Unexpected light surfaces: #{findings.join('; ')}"
  end

  teardown do
    page.execute_script("localStorage.removeItem('crewbase.theme')") if page.current_url.start_with?("http")
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end
end
