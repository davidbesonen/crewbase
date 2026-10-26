require "test_helper"

class BookingAvailabilityTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "connected but failed or stale calendars do not establish availability" do
    profile = Profile.new(ical_feed_url: "https://example.com/calendar.ics", ical_last_synced_at: 3.days.ago)
    job = Job.new(starts_at: 5.days.from_now, ends_at: 6.days.from_now)
    assert_equal :unknown, ProfileJobAvailability.new(profile:, job:).result.state
    profile.ical_last_synced_at = Time.current
    profile.ical_sync_error = "Unavailable"
    assert_equal :unknown, ProfileJobAvailability.new(profile:, job:).result.state
    profile.ical_sync_error = nil
    assert_equal :no_known_conflict, ProfileJobAvailability.new(profile:, job:).result.state
  end
end
