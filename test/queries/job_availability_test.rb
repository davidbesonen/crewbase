require "test_helper"

class JobAvailabilityTest < ActiveSupport::TestCase
  test "ignores blockouts between selected work dates" do
    job = Job.new(
      starts_at: Time.zone.parse("2026-09-01 08:00"),
      ends_at: Time.zone.parse("2026-12-31 18:00"),
      work_dates: [ Date.new(2026, 9, 5), Date.new(2026, 11, 14) ]
    )
    between_stops = CalendarEvent.new(
      event_type: "blockout",
      from_date: Time.zone.parse("2026-10-10 09:00"),
      to_date: Time.zone.parse("2026-10-10 17:00")
    )
    on_stop = CalendarEvent.new(
      event_type: "blockout",
      from_date: Time.zone.parse("2026-11-14 09:00"),
      to_date: Time.zone.parse("2026-11-14 17:00")
    )

    assert_equal [ Date.new(2026, 11, 14) ],
      JobAvailability.new(job:).conflict_dates(events: [ between_stops, on_stop ])
  end
end
