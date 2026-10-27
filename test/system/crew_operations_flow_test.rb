require "application_system_test_case"
require "caxlsx"

class CrewOperationsFlowTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Tour", last_name: "Owner", email: "crew-ops-owner@example.com", password: "password123")
    @owner.assignments.create!(role: Role.find_or_create_by!(name: "user"))
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Crew Operations", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    plan = Plan.create!(PricingCatalog.definitions.last)
    @company.company_plans.create!(plan:)
    login_as @owner, scope: :user
  end

  test "an owner reviews an Excel roster and a crew member completes their imported account" do
    file = Tempfile.new([ "crew-operations", ".xlsx" ])
    package = Axlsx::Package.new
    package.workbook.add_worksheet(name: "Crew") do |sheet|
      sheet.add_row [ "First Name", "Last Name", "Email", "Phone", "City", "State", "Years Worked With", "Job Title", "Notes" ]
      sheet.add_row [ "Alex", "Lighting", "crew-ops-alex@example.com", "6155550160", "Austin", "TX", 4, "Lighting Director", "Private history" ]
      sheet.add_row [ "Skip", "Person" ]
    end
    package.serialize(file.path)
    visit new_usr_company_crew_import_path(@company)
    attach_file "Excel (.xlsx) or CSV file", file.path
    click_button "Upload And Review"
    assert_text "Review Crew Import"
    assert_equal 0, @company.crew_members.count
    click_button "Clear Selection"
    assert_button "Add Selected Crew To Roster", disabled: true
    click_button "Select Ready Rows"
    assert_text "1 of 2 selected"
    fill_in "Find a person in this spreadsheet", with: "NoSuchPerson"
    assert_text "No matching people"
    fill_in "Find a person in this spreadsheet", with: "Alex"
    assert_no_selector "[data-import-row='3']"
    find("[data-import-row='2'] summary").click
    fill_in "crew_import_0_city", with: "Nashville"
    fill_in "Find a person in this spreadsheet", with: ""
    page.save_screenshot("/private/tmp/knowshow-crew-import-review.png")
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 900, deviceScaleFactor: 1, mobile: true)
    select "Dark", from: "Appearance"
    assert_selector "html[data-bs-theme='dark']"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    page.save_screenshot("/private/tmp/knowshow-crew-import-review-dark-mobile.png")
    select "Light", from: "Appearance"
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    click_button "Add Selected Crew To Roster"
    assert_text "Added 1 crew to your private roster."
    assert_text "Alex Lighting"
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 900, deviceScaleFactor: 1, mobile: true)
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    page.save_screenshot("/private/tmp/knowshow-crew-roster-mobile.png")
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    click_link "Alex Lighting"
    click_button "Create Invitation Link"
    claim_url = find("#crew_claim_link").value
    assert claim_url.include?("crew-invitations")
    visit claim_url
    assert_text "different account"
    click_button "Use A Different Account"
    assert_current_path new_user_session_path
    visit claim_url
    assert_field "First name", with: "Alex"
    fill_in "Password (6 characters minimum)", with: "password123"
    fill_in "Confirm password", with: "password123"
    click_button "Create Account"
    assert_button "Claim And Complete My Profile"
    click_button "Claim And Complete My Profile"
    assert_text "Your imported details are ready"
    member = @company.crew_members.first
    assert member.reload.profile_id?
    assert_equal "Nashville", member.profile.primary_location.city
    assert_equal "Lighting Director", member.profile.headline
    assert_not_includes member.profile.attributes.values.join(" "), "Private history"
  ensure
    file&.close!
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end

  test "an owner plans a private gig and prints a useful show brief on desktop and mobile" do
    job = @company.jobs.create!(title: "Nashville Show", description: "A touring show", status: :published, audience: :invite_only, posting_type: :multi_position, workplace_type: :on_site, employment_type: :contract, starts_at: "2030-06-01", ends_at: "2030-06-03")
    job.crew_positions.create!(title: "Lighting Tech", headcount: 2)
    @company.crew_members.create!(first_name: "Casey", last_name: "Crew", phone: "6155550161")
    venue = @company.venues.create!(name: "Music Hall", address: "10 Music Street", city: "Nashville", state: "TN", load_in_notes: "West dock", parking_notes: "Crew lot B")
    visit usr_job_production_path(job)
    select venue.name, from: "Saved venue"
    fill_in "Production contact", with: "Tour Manager"
    fill_in "Contact phone", with: "6155550162"
    fill_in "Show notes / instructions", with: "Wear show blacks. Dinner at 5 PM."
    @company.venues.create!(name: "Newly Added Hall")
    click_link "Refresh Venue List"
    assert_select "Saved venue", options: [ "Use posting location", "Music Hall", "Newly Added Hall" ]
    assert_field "Show notes / instructions", with: "Wear show blacks. Dinner at 5 PM."
    select venue.name, from: "Saved venue"
    click_button "Save Show Information"
    assert_text "Show information saved."
    within "form[action='#{usr_job_production_days_path(job)}']" do
      fill_in "Date", with: Date.new(2030, 6, 1)
      select "Load In", from: "Day / phase"
      fill_in "Label (optional)", with: "Main Stage"
      click_button "Add Schedule Item"
    end
    assert_text "Schedule saved."
    assert_equal "Main Stage", job.production_days.last.label
    assert_no_field "Label (optional)", with: "Main Stage"
    within "form[action='#{usr_job_production_days_path(job)}']" do
      fill_in "Date", with: Date.new(2030, 6, 2)
      fill_in "Label (optional)", with: "Keep my correction"
      fill_in "Starts (optional)", with: Time.zone.local(2030, 6, 2, 15, 0)
      fill_in "Ends (optional)", with: Time.zone.local(2030, 6, 2, 14, 0)
      click_button "Add Schedule Item"
    end
    assert_text "must be after the start"
    assert_field "Label (optional)", with: "Keep my correction"
    page.save_screenshot("/private/tmp/knowshow-production-validation.png")
    visit usr_company_staffing_path(@company, from: "2030-06-01")
    find("summary", text: "Plan From Your Roster").click
    select "Casey Crew · Not claimed", from: "Roster crew member"
    click_button "Add Tentative Crew"
    assert_text "Casey Crew"
    assert_selector ".fw-semibold", text: "Casey Crew", count: 1
    assert_text "0 confirmed"
    page.save_screenshot("/private/tmp/knowshow-staffing-board-desktop.png")
    visit usr_job_brief_path(job)
    assert_text "West dock"
    assert_text "Main Stage"
    assert_text "No confirmed crew yet"
    assert_button "Print / Save PDF"
    page.save_screenshot("/private/tmp/knowshow-show-brief-desktop.png")
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "print")
    assert_no_selector ".navbar", visible: true
    assert_selector "[data-show-brief]"
    page.save_screenshot("/private/tmp/knowshow-show-brief-print.png")
    page.driver.browser.execute_cdp("Emulation.setEmulatedMedia", media: "screen")
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 900, deviceScaleFactor: 1, mobile: true)
    assert_operator find(".app-top-nav").native.rect.height, :<=, 80
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    page.save_screenshot("/private/tmp/knowshow-show-brief-mobile.png")
    visit usr_company_staffing_path(@company, from: "2030-06-01")
    assert_select "Company Workspace", selected: "Staffing Board"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    page.save_screenshot("/private/tmp/knowshow-staffing-board-mobile.png")
    select "Venues", from: "Company Workspace"
    assert_text "Saved Venues & Contacts"
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end

  test "tour stop setup is short and private publication wording follows visibility" do
    project = @company.projects.create!(name: "Summer Route")
    visit new_usr_project_tour_stops_path(project)
    assert_text "Create Your First Gig Setup"
    click_link "Create A Gig"
    assert_button "Activate Private Posting"
    select "Public listing — accept applications", from: "Who can see this posting?"
    assert_button "Publish Job"
    assert_no_button "Activate Private Posting"

    source = @company.jobs.create!(title: "Tour Setup", description: "Touring", status: :draft, posting_type: :multi_position, workplace_type: :on_site, employment_type: :contract, starts_at: "2030-06-01", ends_at: "2030-06-02")
    source.crew_positions.create!(title: "Stage Tech", headcount: 2)
    visit new_usr_project_tour_stops_path(project)
    select "Gig: Tour Setup", from: "Gig or template to reuse"
    fill_in "Gig title", with: "Austin Show"
    fill_in "Start date", with: Date.new(2030, 7, 1)
    click_button "Add Another Stop"
    within all("[data-tour-stop-row]").last do
      fill_in "Gig title", with: "Dallas Show"
      fill_in "Start date", with: Date.new(2030, 7, 4)
    end
    page.save_screenshot("/private/tmp/knowshow-tour-stops-desktop.png")
    click_button "Create Draft Tour Stops"
    assert_text "Created 2 private draft tour stops"
    assert_equal [ "Austin Show", "Dallas Show" ], project.jobs.order(:starts_at).pluck(:title)
    assert project.jobs.all? { |job| job.invite_only? && job.draft? }
  ensure
    Warden.test_reset!
  end

  test "a full 500 person roster review saves through the browser" do
    rows = 500.times.map { |index| { "first_name" => "Crew", "last_name" => index.to_s, "email" => "bulk-#{index}@example.com" } }
    batch = @company.crew_imports.create!(uploaded_by: @owner, rows:)
    visit usr_company_crew_import_path(@company, batch)
    assert_text "500 people found"
    click_button "Add Selected Crew To Roster"
    assert_text "Added 500 crew to your private roster", wait: 20
    assert_equal 500, @company.crew_members.count
  ensure
    Warden.test_reset!
  end
end
