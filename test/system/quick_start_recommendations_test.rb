require "application_system_test_case"

class QuickStartRecommendationsTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "a new worker reaches relevant work and can hide and restore a recommendation" do
    worker = User.create!(first_name: "First", last_name: "Visit", email: "first-visit@example.com", password: "password123")
    worker.profiles.create!(profile_type: "user")
    Occupation.create!(name: "FOH Engineer")
    company = Company.create!(name: "System Productions", contact_email: "system@example.com", industries: [ Industry.create!(name: "System Industry") ])
    company.jobs.create!(title: "Tour audio engineer", description: "Tour audio work", employment_type: :contract,
      workplace_type: :on_site, status: :published, is_active: true, required_capability_keys: [ "foh_mixing" ])
    login_as worker, scope: :user
    page.driver.browser.manage.window.resize_to(390, 1000)
    visit usr_dashboards_path
    assert_text "What Brings You To KnowShow?"
    choose "Find work"
    find("summary", text: "Choose Your Roles").click
    check "FOH Engineer"
    click_button "Get started"
    assert_text "Find Your Next Role"
    within "[data-worker-job-recommendation]" do
      assert_text "Tour audio engineer"
      find("summary", text: "Not Interested?").click
      select "Dates don't work", from: "Why hide this recommendation?"
      click_button "Hide recommendation"
    end
    assert_text "Recommendation hidden"
    assert_no_selector "[data-worker-job-recommendation]"
    click_link "Hidden recommendations"
    assert_current_path usr_recommendation_feedback_index_path, wait: 10
    assert_text "Dates don't work"
    click_button "Restore recommendation"
    click_link "Back to dashboard"
    assert_selector "[data-worker-job-recommendation]", text: "Tour audio engineer"
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, page.evaluate_script("window.innerWidth")
  ensure
    Warden.test_reset!
  end
end
