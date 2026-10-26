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
    fill_in "Project name", with: "Autumn tour"
    find("[data-project-options] > summary").click
    fill_in "Starts on", with: Date.new(2030, 2, 10)
    fill_in "Ends on", with: Date.new(2030, 2, 12)
    click_button "Create project & post a job"
    assert_text "Project created successfully."
    project = @company.projects.find_by!(name: "Autumn tour")
    assert_current_path new_usr_company_job_path(@company, project_id: project.id)
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
    click_button "Publish job"
    assert_current_path usr_project_path(project)
    assert job.reload.published?
    assert job.is_active?
  ensure
    Warden.test_reset!
  end

  test "a company owner can publish a simple job on mobile without opening extra options" do
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 900, deviceScaleFactor: 1, mobile: true)
    visit new_usr_company_project_path(@company)
    fill_in "Project name", with: "Festival weekend"
    page.save_screenshot("/private/tmp/knowshow-staffing-project-mobile.png")
    click_button "Create project only"
    assert_text "Project created successfully."
    project = @company.projects.find_by!(name: "Festival weekend")
    assert_current_path usr_project_path(project)
    click_link "Add Job Posting"
    fill_in "Job title", with: "Stage Technician"
    find("trix-editor").set("Set up and strike the main stage.")
    assert_selector "details[data-additional-experience]:not([open])"
    assert_selector "details[data-posting-options]:not([open])"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    click_button "Publish job"
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

  private

  def assert_selectable_status(label)
    assert_selector "details[data-posting-options][open]"
    assert_select "Status", selected: label
  end
end
