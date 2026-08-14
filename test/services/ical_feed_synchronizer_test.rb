require "test_helper"

class IcalFeedSynchronizerTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    user = User.create!(
      first_name: "Calendar",
      last_name: "Sync",
      email: "ical-sync@example.com",
      password: "password123"
    )
    @profile = user.profiles.create!(
      profile_type: "user",
      ical_feed_url: "https://calendar.example.com/private.ics"
    )
  end

  test "updates matching days and removes stale iCal days without touching manual blockouts" do
    stale = @profile.calendar_events.create!(
      provider: :ical,
      external_id: "old-event:2026-08-03",
      event_type: "blockout",
      name: "Old title",
      from_date: "2026-08-03",
      to_date: "2026-08-03"
    )
    manual = @profile.calendar_events.create!(
      provider: :manual,
      external_id: "manual:2026-08-04",
      event_type: "blockout",
      name: "Manual",
      from_date: "2026-08-04",
      to_date: "2026-08-04"
    )
    calendar = <<~ICAL
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VEVENT
      UID:production-123
      DTSTART;VALUE=DATE:20260810
      DTEND;VALUE=DATE:20260812
      SUMMARY:Production
      END:VEVENT
      END:VCALENDAR
    ICAL

    travel_to Time.zone.local(2026, 8, 1, 12) do
      assert_difference -> { @profile.calendar_events.ical.count }, 1 do
        IcalFeedSynchronizer.new(profile: @profile, fetcher: ->(_url) { calendar }).call
      end
    end

    assert_not CalendarEvent.exists?(stale.id)
    assert CalendarEvent.exists?(manual.id)
    assert_equal(
      [ "production-123:2026-08-10", "production-123:2026-08-11" ],
      @profile.calendar_events.ical.order(:from_date).pluck(:external_id)
    )
    assert_equal [ "Production", "Production" ], @profile.calendar_events.ical.order(:from_date).pluck(:name)
    assert @profile.reload.ical_last_synced_at.present?
    assert_nil @profile.ical_sync_error
  end

  test "keeps the last successful snapshot and records an error when fetching fails" do
    existing = @profile.calendar_events.create!(
      provider: :ical,
      external_id: "existing:2026-08-05",
      event_type: "blockout",
      from_date: "2026-08-05",
      to_date: "2026-08-05"
    )

    result = IcalFeedSynchronizer.new(
      profile: @profile,
      fetcher: ->(_url) { raise OpenURI::HTTPError.new("403 Forbidden", nil) }
    ).call

    assert_not result.success?
    assert CalendarEvent.exists?(existing.id)
    assert_match(/403 Forbidden/, @profile.reload.ical_sync_error)
    assert @profile.ical_sync_attempted_at.present?
    assert_nil @profile.ical_last_synced_at
  end
end
