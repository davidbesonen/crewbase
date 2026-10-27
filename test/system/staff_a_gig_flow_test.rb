require "application_system_test_case"

class StaffAGigFlowTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Staffing", last_name: "Owner", email: "staff-gig-browser@example.com", password: "password123")
    @owner.assignments.create!(role: Role.find_or_create_by!(name: "user"))
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Road Crew Co", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @company.company_plans.create!(plan: Plan.create!(PricingCatalog.definitions.first))
    login_as @owner, scope: :user
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.manage.window.resize_to(1440, 1100)
  end

  test "dashboard starts a single gig and takes the owner directly to crew staffing" do
    visit usr_dashboards_path
    within "[data-company-tools]" do
      assert_link "Staff a Gig"
      click_link "Staff a Gig"
    end
    assert_text "Staff A Gig"
    page.save_screenshot("/private/tmp/knowshow-staff-a-gig-desktop.png")
    choose "staffing_kind_single"
    click_button "Continue"
    assert_text "Set Up Your Gig"
    assert_checked_field "Multiple People Or Roles"
    fill_in "Gig title", with: "Friday Night Concert"
    fill_in "Role title", with: "Stage Tech"
    fill_in "How many people?", with: 2
    find("trix-editor").set("Set up and strike the live show.")
    click_button "Activate Private Gig"
    assert_text "Crew For Friday Night Concert"
    job = @company.jobs.find_by!(title: "Friday Night Concert")
    assert_current_path usr_job_crew_path(job)
    assert job.invite_only?
    assert_equal 2, job.crew_positions.first.headcount
    assert_nil job.project_id
  ensure
    Warden.test_reset!
  end

  test "a tour starts with a project route and plans touring and local crew separately" do
    member = @company.crew_members.create!(first_name: "Alex", last_name: "Local", phone: "6155550170")
    visit usr_dashboards_path
    within("[data-company-tools]") { click_link "Staff a Tour / Festival" }
    fill_in "Tour, festival or project name", with: "Northern Lights Tour"
    click_button "Create Project & Add Shows"
    assert_text "Add Shows & Cities"
    project = @company.projects.find_by!(name: "Northern Lights Tour")
    assert project.multi_show?
    assert_empty project.jobs
    fill_in "Show / Event Name", with: "Opening Night"
    fill_in "City", with: "Austin"
    fill_in "Show Date", with: Date.new(2030, 10, 1)
    click_button "Add Another Show"
    within all("[data-tour-stop-row]").last do
      fill_in "Show / Event Name", with: "Second Night"
      fill_in "City", with: "Dallas"
      fill_in "Show Date", with: Date.new(2030, 10, 3)
    end
    click_button "Save Shows"
    assert_current_path usr_project_path(project)
    assert_selector "[data-project-show]", count: 2
    assert_empty project.jobs
    page.save_screenshot("/private/tmp/knowshow-tour-shows-desktop.png")
    click_link "Crew By Show"
    click_link "Plan Crew / Add Open Role"
    fill_in "Role", with: "Tour Manager"
    click_button "Add Crew Need"
    assert_current_path usr_project_path(project, view: "crew")
    click_link "Plan Crew / Add Open Role"
    fill_in "Role", with: "Local Stagehand"
    select member.full_name, from: "Crew Member (Optional)"
    select "Selected shows / cities", from: "Coverage"
    check project.project_shows.find_by!(city: "Dallas").display_name
    click_button "Add Crew Need"
    assert_current_path usr_project_path(project, view: "crew")
    assert_selector "[data-crew-show-row]", count: 2
    manager = project.jobs.find_by!(title: "Tour Manager")
    local = project.jobs.find_by!(title: "Local Stagehand")
    assert_equal 2, manager.project_shows.count
    assert_equal [ "Dallas" ], local.project_shows.pluck(:city)
    within "[data-crew-show-row='#{local.id}']" do
      assert_text "Alex Local"
      assert_text "1 tentative"
      assert_selector "[data-show-covered]", count: 1
      click_link "Edit Shows / Role"
    end
    assert_select "Where Is This Crew Needed?", selected: "Selected shows / cities"
    assert_field "Start date (optional)", disabled: true
    uncheck project.project_shows.find_by!(city: "Dallas").display_name
    check project.project_shows.find_by!(city: "Austin").display_name
    click_button "Save changes", exact: true
    assert_current_path usr_project_path(project)
    assert_equal [ "Austin" ], local.reload.project_shows.pluck(:city)
    visit usr_project_path(project, view: "crew")
    page.save_screenshot("/private/tmp/knowshow-tour-crew-desktop.png")
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 1000, deviceScaleFactor: 1, mobile: true)
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    page.save_screenshot("/private/tmp/knowshow-tour-crew-mobile.png")
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end

  test "posting a job asks whether it belongs to a project or existing crew gig" do
    project = @company.projects.create!(name: "Summer Festival", project_type: :multi_show)
    project.project_shows.create!(name: "Main Stage", city: "Chicago", starts_on: "2030-06-01")
    gig = @company.jobs.create!(title: "Friday Concert", posting_type: :multi_position, status: :draft, workplace_type: :on_site, employment_type: :contract)
    visit usr_dashboards_path
    within("[data-company-tools]") { click_link "Post a Job" }
    choose "placement_kind_project"
    select project.name, from: "Tour / Festival Project"
    click_button "Continue"
    assert_text "Roles Needed For These Shows"
    assert_no_text "Multi-position gig"
    assert_select "Where Is This Crew Needed?", selected: "Entire run — including shows added later"
    choose "Several Roles / People For The Same Shows"
    assert_field "Crew posting title"
    page.save_screenshot("/private/tmp/knowshow-project-role-form.png")
    visit new_usr_company_job_placement_path(@company)
    choose "placement_kind_gig"
    select gig.title, from: "Existing Gig"
    click_button "Continue"
    assert_text "Crew For Friday Concert"
    fill_in "Position title", with: "Lighting Tech"
    click_button "Add", exact: true
    assert_text "Lighting Tech"
    assert_equal 1, gig.crew_positions.count
  ensure
    Warden.test_reset!
  end
end
