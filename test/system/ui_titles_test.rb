require "application_system_test_case"

class UiTitlesTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "headings use title case while names product spelling and body copy keep their authored case" do
    owner = User.create!(first_name: "Dayne", last_name: "deHaven", email: "title-owner@example.com", password: "password123")
    owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    owner.visits.create!
    company = Company.create!(name: "iCal Productions", contact_email: "titles@example.com", industries: [ Industry.music_touring! ])
    company.company_assignments.create!(user: owner, role: "owner")
    job = company.jobs.create!(title: "grandMA3 programmer", description: "Program the show.", employment_type: :contract, workplace_type: :on_site)
    login_as owner, scope: :user

    page.driver.browser.manage.window.resize_to(1440, 1100)
    visit new_usr_company_job_path(company)
    assert_selector "h2", text: "When, Where & Pay"
    assert_selector "h2", text: "Who Do You Need?"
    assert_selector "legend", text: "What Are You Posting?"
    assert_selector "summary", text: "Posting Settings"
    find("[data-additional-experience] > summary").click
    assert_selector "legend", text: "Required Capabilities"
    page.execute_script("document.querySelector('[data-schedule-options]').scrollIntoView({block: 'center', behavior: 'instant'})")
    page.save_screenshot("/private/tmp/knowshow-titles-desktop.png")

    visit usr_job_path(job)
    assert_selector "h1", exact_text: "grandMA3 programmer"
    visit usr_profile_path(owner.user_profile)
    assert_selector "h1", text: "Dayne deHaven"
    visit welcome_path
    assert_selector "h1", text: "Know Your Gigs."
    assert_selector ".marketing-hero__lede", text: /Know who’s on your crew and where each gig stands/
  ensure
    Warden.test_reset!
  end
end
