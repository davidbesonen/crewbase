require "application_system_test_case"

class JobPostingStatusTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Alex", last_name: "Bennett", email: "filled-browser@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Touring Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @project = @company.projects.create!(name: "Christmas Tour", status: :active, project_type: :multi_show)
    @job = @company.jobs.create!(title: "Lighting Engineer", description: "Operate the lighting console for the tour.", status: :published, published_at: Time.current, is_active: true, employment_type: :contract, workplace_type: :on_site, project: @project)
    login_as @owner, scope: :user
  end

  test "owner closes recruiting from a project and can reopen from the posting" do
    visit usr_project_path(@project, view: "roles")
    within "[data-project-job='#{@job.id}']" do
      click_button "Mark as Filled"
    end
    assert_selector "[data-project-job='#{@job.id}']", text: "Filled"
    assert @job.reload.filled?
    visit usr_job_path(@job)
    assert_button "Reopen Posting"
    page.save_screenshot("/private/tmp/knowshow-job-filled.png")
    click_button "Reopen Posting"
    assert_button "Mark as Filled"
    assert @job.reload.published?
    visit usr_job_production_path(@job)
    assert_button "Mark as Filled"
  end

  test "project card whitespace opens the project in light and dark modes on desktop and mobile" do
    [ [ 1440, "light" ], [ 390, "dark" ] ].each do |width, theme|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: width, height: 1000, deviceScaleFactor: 1, mobile: width < 600)
      visit usr_company_projects_path(@company)
      page.execute_script("document.documentElement.setAttribute('data-bs-theme', arguments[0])", theme)
      assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, width
      card = find(".project-link-card")
      card.hover
      page.save_screenshot("/private/tmp/knowshow-project-card-#{theme}.png")
      # Click the card's blank lower-right corner, away from its title link.
      card.click(x: card.native.rect.width / 2 - 30, y: card.native.rect.height / 2 - 24)
      assert_current_path usr_project_path(@project)
      assert_text "Christmas Tour"
    end
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end

  teardown { Warden.test_reset! }
end
