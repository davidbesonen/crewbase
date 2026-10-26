require "application_system_test_case"

class AdminManagementSystemTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "owner investigates a report restricts a job and restores it on mobile" do
    owner = User.create!(first_name: "Site", last_name: "Owner", email: "admin-system@example.com", password: "password123")
    owner.roles << Role.find_or_create_by!(name: "app_owner")
    owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    owner.visits.create!
    company = Company.create!(name: "Harbor Production", contact_email: "harbor@example.com", industries: [ Industry.create!(name: "Admin system") ])
    job = company.jobs.create!(title: "Festival camera operator", description: "Support the festival broadcast team.", status: :published, workplace_type: :on_site, employment_type: :contract)
    report = SafetyReport.create!(reporter: owner, subject: job, subject_label: job.title, category: "spam", details: "Please review the posting details.")
    login_as owner, scope: :user

    page.driver.browser.manage.window.resize_to(1400, 1200)
    visit admin_root_path
    assert_selector "h1", text: "Admin Dashboard"
    click_link "Reports", exact: true
    click_link job.title
    click_link "Manage job ##{job.id}"
    assert_selector "h1", text: job.title
    select "Hide from discovery and stop applications", from: "Action"
    fill_in "Reason (internal only)", with: "Investigating a misleading posting report."
    accept_confirm { click_button "Apply change" }
    assert_text "Change saved and recorded in the audit log."
    assert_selector ".badge", text: "Restricted", exact_text: true
    assert job.reload.restricted_at?
    assert_text "Investigating a misleading posting report."
    page.save_screenshot("/private/tmp/crewbase-admin-detail-desktop.png")

    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 1000, deviceScaleFactor: 1, mobile: true)
    assert_equal 390, page.evaluate_script("window.innerWidth")
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, page.evaluate_script("window.innerWidth")
    page.save_screenshot("/private/tmp/crewbase-admin-detail-mobile.png")
    select "Restore access / visibility", from: "Action"
    fill_in "Reason (internal only)", with: "The listing was corrected and verified."
    accept_confirm { click_button "Apply change" }
    assert_selector ".badge", text: "Unrestricted", exact_text: true
    assert job.reload.accepting_applications?
    find("button[aria-label='Toggle admin navigation']").click
    click_link "Audit log", exact: true
    assert_selector "h1", text: "Audit Log"
    assert_text "The listing was corrected and verified."
    assert_text "Investigating a misleading posting report."
    page.save_screenshot("/private/tmp/crewbase-admin-audit-mobile.png")
    visit admin_report_path(report)
    select "Resolved", from: "Decision"
    fill_in "Findings and actions taken", with: "Restored the corrected posting after review."
    click_button "Record decision"
    assert_text "Decision recorded."
    assert report.reload.resolved?
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end
end
