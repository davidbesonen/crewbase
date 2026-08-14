require "test_helper"

class ProfileJobAvailabilityTest < ActiveSupport::TestCase
  test "reports unavailable with each conflicting job date" do
    job = Job.new(work_dates: [ Date.new(2026, 8, 8), Date.new(2026, 8, 10) ])
    profile = profile_with(
      CalendarEvent.new(
        event_type: "blockout",
        from_date: Time.zone.parse("2026-08-08 08:00"),
        to_date: Time.zone.parse("2026-08-10 18:00")
      )
    )

    result = ProfileJobAvailability.new(profile:, job:).result

    assert_equal :unavailable, result.state
    assert_equal "Unavailable Aug 8 and Aug 10", result.label
    assert_equal [ Date.new(2026, 8, 8), Date.new(2026, 8, 10) ], result.conflict_dates
  end

  test "reports no known conflict when dated job does not overlap calendar evidence" do
    job = Job.new(
      starts_at: Time.zone.parse("2026-08-08 08:00"),
      ends_at: Time.zone.parse("2026-08-10 18:00")
    )
    profile = profile_with(
      CalendarEvent.new(
        event_type: "blockout",
        from_date: Time.zone.parse("2026-08-11 08:00"),
        to_date: Time.zone.parse("2026-08-11 18:00")
      )
    )

    result = ProfileJobAvailability.new(profile:, job:).result

    assert_equal :no_known_conflict, result.state
    assert_equal "No known conflict", result.label
    assert_empty result.conflict_dates
  end

  test "treats a connected calendar feed as availability evidence" do
    job = Job.new(starts_at: Time.zone.parse("2026-08-08 08:00"))
    profile = profile_with(ical_feed_url: "https://example.com/calendar.ics")

    result = ProfileJobAvailability.new(profile:, job:).result

    assert_equal :no_known_conflict, result.state
    assert_equal "No known conflict", result.label
  end

  test "reports unknown when the job has no usable dates" do
    profile = profile_with(
      CalendarEvent.new(
        event_type: "blockout",
        from_date: Time.zone.parse("2026-08-11 08:00"),
        to_date: Time.zone.parse("2026-08-11 18:00")
      )
    )

    result = ProfileJobAvailability.new(profile:, job: Job.new).result

    assert_equal :unknown, result.state
    assert_equal "Availability unknown", result.label
    assert_empty result.conflict_dates
  end

  test "reports unknown when the profile has no availability evidence" do
    job = Job.new(starts_at: Time.zone.parse("2026-08-08 08:00"))

    result = ProfileJobAvailability.new(profile: profile_with, job:).result

    assert_equal :unknown, result.state
    assert_equal "Availability unknown", result.label
    assert_empty result.conflict_dates
  end

  private

  def profile_with(*events, ical_feed_url: nil)
    Struct.new(:calendar_events, :ical_feed_url).new(events, ical_feed_url)
  end
end
