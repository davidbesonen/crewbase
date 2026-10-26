require "application_system_test_case"

class AvailabilityCalendarTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "availability calendar loads without failed controller imports and saves manual blockouts" do
    user = User.create!(first_name: "Calendar", last_name: "Worker", email: "calendar-system@example.com", password: "password123")
    profile = user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    login_as user, scope: :user

    visit edit_calendar_usr_profile_path(profile)
    assert_selector "#availability_calendar .availability-table"
    date = Date.current
    within "#availability_date_#{date.iso8601}" do
      find("a").click
      assert_selector "a.btn-danger"
    end
    event = profile.calendar_events.find_by!(provider: :manual, external_id: date.strftime("%-m/%-d/%Y"))
    assert_equal "blockout", event.event_type
    assert_equal date, event.to_date.to_date
    assert_selector "#blockout_dates_list", text: date.strftime("%A, %B %d, %Y")

    errors = page.driver.browser.logs.get(:browser).select { |entry| entry.level == "SEVERE" && entry.message.include?("availability-calendar") }
    assert_empty errors.map(&:message), "Availability must not load a broken Stimulus controller"

    within "#availability_date_#{date.iso8601}" do
      find("a").click
      assert_selector "a.btn-outline-secondary"
    end
    assert_not profile.calendar_events.exists?(id: event.id)

    within "#availability_date_#{date.iso8601}" do
      find("a").click
      assert_selector "a.btn-danger"
    end
    within "#blockout_dates_list" do
      click_link "Clear all"
      assert_text "No blockout dates"
    end
    assert_empty profile.calendar_events.reload

  ensure
    Warden.test_reset!
  end
end
