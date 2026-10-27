require "application_system_test_case"

class ProjectStaffingFlowTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Tour", last_name: "Owner", email: "streamlined-staffing@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Staffing Productions", contact_email: "staffing@example.com", industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    plan = Plan.create!(name: "Starter", key: "free", monthly_price_cents: 0, annual_price_cents: 0, data: { "active_jobs_limit" => 5, "projects_limit" => 3 })
    @company.company_plans.create!(plan:)
    login_as @owner, scope: :user
  end

  test "project creation flows straight into a dated draft and then a published job" do
    page.driver.browser.manage.window.resize_to(1440, 1100)
    visit new_usr_company_project_path(@company)
    assert_selector "details[data-project-options]:not([open])"
    fill_in "Tour, festival or project name", with: "Autumn tour"
    find("[data-project-options] > summary").click
    fill_in "Starts on", with: Date.new(2030, 2, 10)
    fill_in "Ends on", with: Date.new(2030, 2, 12)
    click_button "Create project & post a job"
    assert_text "Project created successfully."
    project = @company.projects.find_by!(name: "Autumn tour")
    assert_current_path new_usr_company_job_path(@company, project_id: project.id)
    select "Custom dates — not linked to shows", from: "Where Is This Crew Needed?"
    assert_field "Start date (optional)", with: "2030-02-10"
    assert_field "End date (optional)", with: "2030-02-12"
    assert_checked_field "Single job posting"
    fill_in "Job title", with: "FOH Audio Engineer"
    page.save_screenshot("/private/tmp/knowshow-staffing-job-desktop.png")
    click_button "Save draft"
    assert_current_path usr_project_path(project)
    job = project.jobs.find_by!(title: "FOH Audio Engineer")
    assert job.draft?
    assert_nil job.published_at
    assert_equal Date.new(2030, 2, 12), job.ends_at.to_date
    visit edit_usr_company_job_path(@company, job)
    assert_selectable_status "Draft"
    find("trix-editor").set("Mix live audio for the tour.")
    click_button "Publish Job"
    assert_current_path usr_project_path(project)
    assert job.reload.published?
    assert job.is_active?
  ensure
    Warden.test_reset!
  end

  test "a company owner can publish a simple job on mobile without opening extra options" do
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 900, deviceScaleFactor: 1, mobile: true)
    visit new_usr_company_project_path(@company)
    fill_in "Tour, festival or project name", with: "Festival weekend"
    page.save_screenshot("/private/tmp/knowshow-staffing-project-mobile.png")
    click_button "Create project only"
    assert_text "Project created successfully."
    project = @company.projects.find_by!(name: "Festival weekend")
    assert_current_path usr_project_path(project)
    click_link "Post A Job"
    fill_in "Job title", with: "Stage Technician"
    find("trix-editor").set("Set up and strike the main stage.")
    assert_selector "details[data-additional-experience]:not([open])"
    assert_selector "details[data-posting-options]:not([open])"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    select "Public listing — accept applications", from: "Who can see this posting?"
    click_button "Publish Job"
    assert_current_path usr_project_path(project)
    job = project.jobs.find_by!(title: "Stage Technician")
    assert job.published?
    assert job.contract?
    assert job.on_site?
    assert_empty job.work_dates
    assert_empty job.questions
    assert_empty job.locations
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end

  test "tour shows use venue search optional names and custom counts on mobile" do
    project = @company.projects.create!(name: "Venue Search Tour", project_type: :multi_show)
    VenueCatalogEntry.create!(source_key: "way/404", name: "Red Rocks Amphitheatre", city: "Morrison", state: "CO", country: "US", address: "18300 West Alameda Parkway")
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 1100, deviceScaleFactor: 1, mobile: true)
    visit new_usr_project_project_show_path(project)
    fill_in "Venue (Optional)", with: "Red Rocks"
    assert_selector "datalist option[value='Red Rocks Amphitheatre — Morrison, CO']", visible: :all
    fill_in "Venue (Optional)", with: "Red Rocks Amphitheatre — Morrison, CO"
    assert_field "City", with: "Morrison"
    assert_field "State / Region", with: "CO"
    fill_in "Show Date", with: Date.new(2030, 10, 1)
    fill_in "Show Time (Optional)", with: "19:30"
    select "Other", from: "Number Of Shows (Optional)"
    fill_in "How Many Shows?", with: "5"
    click_button "Add Another Show"
    within all("[data-tour-stop-row]").last do
      assert_text "Search U.S. venues by name or city, or enter your own."
      assert_field "Show Time (Optional)", with: ""
      assert_select "Number Of Shows (Optional)", selected: "1"
      assert_no_selector "input[name$='[show_count]']", visible: true
      fill_in "City", with: "Denver"
      fill_in "Show Date", with: Date.new(2030, 10, 2)
    end
    assert_equal 2, page.all("datalist", visible: :all).map { |element| element[:id] }.uniq.size
    page.save_screenshot("/private/tmp/knowshow-tour-show-form-mobile.png")
    click_button "Save Shows"
    assert_current_path usr_project_path(project)
    first, second = project.project_shows.chronological
    assert_equal "Morrison", first.name
    assert_equal "Red Rocks Amphitheatre", first.venue_name
    assert_equal 5, first.show_count
    assert_equal "19:30", first.show_time.strftime("%H:%M")
    assert_nil first.ends_on
    assert_equal 1, second.show_count
    assert_equal "Denver", second.name
    assert_nil second.show_time
    assert_text "5 shows"
    assert_text "7:30 PM local"
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end

  test "catalog venues can be saved privately and selected in a production brief" do
    entry = VenueCatalogEntry.create!(source_key: "way/405", name: "Touring Music Hall", city: "Austin", state: "TX", country: "US", address: "10 Music Street")
    visit new_usr_company_venue_path(@company)
    fill_in "Name", with: "Touring Music"
    assert_selector "datalist option[value='Touring Music Hall — Austin, TX']", visible: :all
    fill_in "Name", with: "Touring Music Hall — Austin, TX"
    assert_field "City", with: "Austin"
    assert_field "Address", with: "10 Music Street"
    fill_in "Load in notes", with: "Company-only dock instructions"
    click_button "Save Venue"
    assert_current_path usr_company_venues_path(@company)
    venue = @company.venues.find_by!(venue_catalog_entry: entry)
    job = @company.jobs.create!(title: "Austin Crew", status: :draft, employment_type: :contract, workplace_type: :on_site)
    visit usr_job_production_path(job)
    fill_in "Find A U.S. Venue", with: "Touring Music"
    assert_selector "datalist option[value='Touring Music Hall — Austin, TX']", visible: :all
    fill_in "Find A U.S. Venue", with: "Touring Music Hall — Austin, TX"
    click_button "Save Show Information"
    assert_current_path usr_job_production_path(job)
    assert_equal venue, job.reload.venue
    assert_equal "Company-only dock instructions", venue.reload.load_in_notes
  ensure
    Warden.test_reset!
  end

  test "same city show columns remain distinguishable on desktop and mobile" do
    project = @company.projects.create!(name: "Lincoln Weekend", project_type: :multi_show)
    early = project.project_shows.create!(name: "Acoustic Set", city: "Lincoln", state: "NE", starts_on: "2030-11-02")
    late = project.project_shows.create!(name: "Main Stage", city: "Lincoln", state: "NE", starts_on: "2030-11-02")
    PlanProjectCrew.new(project:, actor: @owner, attributes: { "title" => "FOH Engineer", "show_coverage" => "all_shows" }).call
    [ 1440, 390 ].each do |width|
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 1100, deviceScaleFactor: 1, mobile: width == 390)
      visit usr_project_path(project, view: "crew")
      assert_selector "th[data-crew-show-column='#{early.id}']", text: "Acoustic Set"
      assert_selector "th[data-crew-show-column='#{late.id}']", text: "Main Stage"
      assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, width
      page.save_screenshot("/private/tmp/knowshow-distinct-show-columns-#{width}.png")
    end
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end

  private

  def assert_selectable_status(label)
    assert_selector "details[data-posting-options][open]"
    assert_select "Status", selected: label
  end
end
