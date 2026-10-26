require "test_helper"

class Usr::JobScheduleComponentTest < ViewComponent::TestCase
  test "date-only postings display dates without invented times" do
    render_inline Usr::JobScheduleComponent.new(job: Job.new(schedule_has_times: false,
      starts_at: "2026-11-09", ends_at: "2026-11-10"))
    assert_text "November 09, 2026"
    assert_no_text "00:00"
    assert_no_text Time.zone.name
  end

  test "timed gigs display exact times and the time zone" do
    render_inline Usr::JobScheduleComponent.new(job: Job.new(schedule_has_times: true,
      starts_at: "2026-11-09 09:30", ends_at: "2026-11-09 18:45"))
    assert_text I18n.l(Time.zone.parse("2026-11-09 09:30"), format: :long)
    assert_text Time.zone.name
  end

  test "ongoing roles indicate flexible dates" do
    render_inline Usr::JobScheduleComponent.new(job: Job.new(schedule_has_times: false))
    assert_text "Flexible / Not listed", count: 2
  end
end
