require "application_system_test_case"

class CrewRosterAuditTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  include ActionMailer::TestHelper
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Excel", last_name: "Owner", email: "excel-browser-owner@example.com", password: "password123")
    @owner.roles << Role.find_or_create_by!(name: "user")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Excel Audit Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @company.company_plans.create!(plan: Plan.create!(PricingCatalog.definitions.last))
    login_as @owner, scope: :user
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    page.driver.browser.manage.window.resize_to(1440, 1100)
  end

  test "real Excel upload to new email-only account preserves privacy and requires an explicit claim" do
    assert_no_enqueued_emails do
      upload("valid")
      assert_text "5 people found"
      assert_equal 0, @company.crew_members.count
      assert_no_selector "script", text: "dummy-note", visible: :all
      click_button "Add Selected Crew To Roster"
      assert_text "Added 5 crew to your private roster"
      assert_text "No accounts were created and no invitations were sent"
      click_link "Alex Audio", exact: true
      assert_text "did not create a login or send an email"
      click_button "Create Invitation Link"
      assert_text "No email or text was sent"
    end
    member = @company.crew_members.find_by!(email: "alex.audio@example.com")
    claim_url = find_field("Invitation link").value
    assert_nil User.find_by(email: member.email)
    logout :user
    visit claim_url
    assert_text "Finish Your KnowShow Profile"
    assert_field "Email", with: member.email
    assert_no_text "Private: first-call crew"
    fill_in "Password (6 characters minimum)", with: "password123"
    fill_in "Confirm password", with: "password123"
    click_button "Create Account"
    assert_button "Claim And Complete My Profile"
    assert_nil member.reload.profile_id
    click_button "Claim And Complete My Profile"
    assert_text "Your imported details are ready"
    profile = member.reload.profile
    assert_equal "FOH Engineer", profile.headline
    assert_equal "Nashville", profile.primary_location.city
    assert_equal "DiGiCo SD series\nDante", profile.equipment_text
    assert_nil profile.completed_at
    assert_nil member.invitation_nonce
    assert_nil member.invitation_expires_at
    assert_not @company.company_assignments.exists?(user: profile.user)
    assert_not_includes profile.attributes.values.join(" "), "Private: first-call crew"
    page.save_screenshot("/private/tmp/knowshow-roster-claimed-profile.png")
    visit claim_url
    assert_text "This Invitation Is Unavailable"
  end

  test "phone-only crew can create an email login and claim on a phone without becoming company staff" do
    upload("valid")
    click_button "Add Selected Crew To Roster"
    assert_text "Added 5 crew"
    click_link "Casey Lighting", exact: true
    assert_text "phone-only contact"
    click_button "Create Invitation Link"
    claim_url = find_field("Invitation link").value
    member = @company.crew_members.find_by!(phone_key: "16155550142")
    logout :user
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 1000, deviceScaleFactor: 1, mobile: true)
    visit claim_url
    assert_text "Your invitation was shared by phone"
    fill_in "Email", with: "casey.lighting@example.com"
    fill_in "Password (6 characters minimum)", with: "password123"
    fill_in "Confirm password", with: "password123"
    click_button "Create Account"
    assert_button "Claim And Complete My Profile"
    click_button "Claim And Complete My Profile"
    assert_text "Your imported details are ready"
    assert_equal "casey.lighting@example.com", member.reload.profile.user.email
    assert_equal "+1 (615) 555-0142", member.profile.contact_phone_number
    assert_equal "Lighting Director", member.profile.headline
    assert_not @company.company_assignments.exists?(user: member.profile.user)
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    page.save_screenshot("/private/tmp/knowshow-roster-phone-claim.png")
  end

  test "real error workbook retains corrections and safely excludes invalid rows" do
    upload("needs-review")
    assert_text "7 people found"
    assert_text "Duplicate contact in this spreadsheet"
    assert_text "Add an email or phone number"
    click_button "Add Selected Crew To Roster"
    assert_text "Select Ready Rows"
    assert_equal 0, @company.crew_members.count
    assert_selector ".is-invalid"
    page.save_screenshot("/private/tmp/knowshow-roster-errors-desktop.png")
    click_button "Clear Selection"
    assert_button "Add Selected Crew To Roster", disabled: true
    check "Include row 2"
    fill_in "crew_import_0_phone", with: "6155550197"
    fill_in "crew_import_0_city", with: "Austin"
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width: 390, height: 1000, deviceScaleFactor: 1, mobile: true)
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, 390
    page.save_screenshot("/private/tmp/knowshow-roster-corrections-mobile.png")
    click_button "Add Selected Crew To Roster"
    assert_text "Added 1 crew to your private roster"
    assert_equal "Austin", @company.crew_members.sole.city
    assert_equal "16155550197", @company.crew_members.sole.phone_key
    assert_nil @company.crew_members.sole.profile_id
  end

  test "existing crew recover from duplicate signup and claim without overwriting their profile" do
    worker = User.create!(first_name: "Alex", last_name: "Audio", email: "alex.audio@example.com", password: "password123")
    profile = worker.profiles.create!(profile_type: "user", headline: "My own headline", bio: "My own biography", completed_at: Time.current)
    upload("valid")
    click_button "Add Selected Crew To Roster"
    assert_text "Added 5 crew"
    click_link "Alex Audio", exact: true
    click_button "Create Invitation Link"
    claim_url = find_field("Invitation link").value
    member = @company.crew_members.find_by!(email: worker.email)
    assert_nil member.profile_id
    logout :user
    visit claim_url
    fill_in "Password (6 characters minimum)", with: "password123"
    fill_in "Confirm password", with: "password123"
    click_button "Create Account"
    assert_text "Email has already been taken"
    click_link "Log in", exact: true
    fill_in "Email", with: worker.email
    fill_in "Password", with: "wrong-password"
    click_button "Log in"
    assert_text "Invalid Email or password"
    fill_in "Password", with: "password123"
    click_button "Log in"
    assert_button "Claim And Complete My Profile"
    click_button "Claim And Complete My Profile"
    assert_text "Your imported details are ready"
    assert_equal profile.id, member.reload.profile_id
    assert_equal "My own headline", profile.reload.headline
    assert_equal "My own biography", profile.bio
    assert profile.completed_at?
    assert_not @company.company_assignments.exists?(user: worker)
  end

  private

  def upload(kind)
    visit new_usr_company_crew_import_path(@company)
    attach_file "Excel (.xlsx) or CSV file", Rails.root.join("test/data/crew-roster-#{kind}.xlsx")
    click_button "Upload And Review"
    assert_text "Review Crew Import"
  end

  teardown do
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end
end
