require "application_system_test_case"

class DashboardRecommendationsLayoutTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "recommendation cards share a height with unequal content at desktop and mobile widths" do
    owner = create_member("owner")
    company = Company.create!(name: "Layout Productions", contact_email: "layout@example.com",
      industries: [ Industry.create!(name: "Layout Industry") ])
    company.company_assignments.create!(user: owner, role: "owner")
    job = company.jobs.create!(title: "Audio crew", description: "Live audio work", workplace_type: :on_site,
      employment_type: :contract, status: :published, is_active: true, required_capability_keys: [ "audio" ])
    3.times { |index| create_member("crew#{index}").user_profile.update!(capability_keys: [ "audio" ]) }
    login_as owner, scope: :user

    [ 1400, 390 ].each do |width|
      page.driver.browser.manage.window.resize_to(width, 1400)
      page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride", width:, height: 1400, deviceScaleFactor: 1, mobile: width < 768)
      visit usr_dashboards_path
      assert_selector "[data-job-matches-empty]"
      assert_selector "[data-crew-recommendation]", count: 3
      assert_selector "[data-people-crews-card] .bi-stars", count: 1
      assert_selector "[data-open-jobs-card] .bi-stars", count: 1
      assert_no_selector "[data-crew-recommendation] .bi-stars"
      jobs = find("[data-dashboard-recommendations] > [data-open-jobs-card] > .card")
      crew = find("[data-people-crews-card] > .card")
      page.execute_script("document.querySelector('[data-people-crews-card]').scrollIntoView({block: 'start', behavior: 'instant'})")
      page.save_screenshot("/private/tmp/knowshow-sparkles-dashboard-#{width}.png")
      assert_in_delta crew.native.rect.height, jobs.native.rect.height, 1, "Card heights differ at #{width}px"
      assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, page.evaluate_script("window.innerWidth")

      visit usr_job_path(job)
      assert_selector "[data-job-crew-recommendation]", count: 3
      assert_selector ".card:has([data-job-crew-recommendation]) .bi-stars", count: 1
      assert_no_selector "[data-job-crew-recommendation] .bi-stars"
      page.execute_script("document.querySelector('[data-job-crew-recommendation]').scrollIntoView({block: 'center', behavior: 'instant'})")
      page.save_screenshot("/private/tmp/knowshow-sparkles-job-#{width}.png")
    end
  ensure
    page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
    Warden.test_reset!
  end

  private

  def create_member(name)
    User.create!(first_name: name, last_name: "Layout", email: "#{name}-layout-system@example.com", password: "password123").tap do |user|
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
      user.visits.create!
    end
  end
end
