require "application_system_test_case"

class WorkInboxTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "crew can triage offers revisit saved jobs and clear unread updates on mobile" do
    owner = create_member("Owner")
    worker = create_member("Worker")
    company = Company.create!(name: "Northstar Test Productions", contact_email: "work-inbox@example.com", industries: [ Industry.create!(name: "Work inbox") ])
    company.company_assignments.create!(user: owner, role: "owner")
    pending = create_offer(company, owner, worker, "Festival lighting designer", :pending)
    confirmed = create_offer(company, owner, worker, "Studio camera operator", :accepted)
    closed_job = company.jobs.create!(title: "Saved closed role", description: "Closed", status: :closed, workplace_type: :on_site, employment_type: :contract)
    worker.saved_jobs.create!(job: closed_job)
    notification = worker.notifications.create!(kind: "system_update", message: "Your work inbox is ready")
    login_as worker, scope: :user

    visit usr_dashboards_path
    within "[data-offers-needing-reply]" do
      assert_text pending.role
      click_link "Review offer"
    end
    assert_selector "h1", text: pending.role
    click_link "All offers"
    click_link "Needs your reply"
    assert_selector "[data-offer-id]", count: 1
    assert_text "Reply due soon"
    fill_in "Search offers", with: "Does not exist"
    click_button "Search"
    assert_text "No Offers Match Your Search"
    assert_selector "nav[aria-label='Filter offers'] a[aria-current='page']", text: /Needs your reply/
    click_link "Clear search"
    assert_selector "[data-offer-id='#{pending.id}']"

    click_link "Confirmed", exact: false
    assert_selector "[data-offer-id='#{confirmed.id}']"
    click_link "View booking"
    assert_selector "a[href='#{calendar_usr_job_offer_path(confirmed)}'][data-turbo='false']", text: "Add to calendar"
    assert_no_selector "textarea[name='reason']", visible: true
    find("summary", text: "Cancel This Booking").click
    assert_field "Cancellation reason"

    visit usr_job_offers_path
    page.save_screenshot("/private/tmp/crewbase-work-inbox-desktop.png")
    page.driver.browser.manage.window.resize_to(390, 1000)
    assert_selector "[data-offer-id]", count: 2
    assert_operator page.evaluate_script("document.documentElement.scrollWidth"), :<=, page.evaluate_script("window.innerWidth")
    page.save_screenshot("/private/tmp/crewbase-work-inbox-mobile.png")

    visit usr_saved_jobs_path
    select "No longer available", from: "Availability"
    click_button "Filter"
    assert_text "Saved closed role"
    within "[data-saved-job='#{closed_job.id}']" do
      click_button "Remove"
    end
    assert_text "Job removed from saved jobs."
    assert_empty worker.saved_jobs.reload
    visit usr_notifications_path
    click_button "Mark all as read"
    assert_text "All notifications marked as read."
    assert notification.reload.read?
    assert_text "Your work inbox is ready"
  ensure
    Warden.test_reset!
  end

  private

  def create_member(name)
    User.create!(first_name: name, last_name: "Crew", email: "#{name.downcase}-work-inbox@example.com", password: "password123").tap do |user|
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
      user.visits.create!
    end
  end

  def create_offer(company, owner, worker, role, status)
    job = company.jobs.create!(title: role, description: "Production work", status: :published, workplace_type: :on_site,
      employment_type: :contract, starts_at: 5.days.from_now, ends_at: 6.days.from_now)
    application = job.job_applications.create!(profile: worker.user_profile)
    application.job_offers.create!(profile: worker.user_profile, sender: owner, role:, status:,
      starts_at: job.starts_at, ends_at: job.ends_at, expires_at: 1.day.from_now, rate: 550, currency: "USD", pay_unit: "daily")
  end
end
