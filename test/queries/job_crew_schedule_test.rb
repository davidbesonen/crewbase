require "test_helper"

class JobCrewScheduleTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "marks assigned profiles whose calendar events overlap the job dates" do
    owner = create_user("owner")
    available = create_user("available").user_profile
    unavailable = create_user("unavailable").user_profile
    industry = Industry.create!(name: "Schedule Industry")
    company = Company.create!(name: "Schedule Company", contact_email: "schedule@example.com", industries: [ industry ])
    company.company_assignments.create!(user: owner, role: "owner")
    job = company.jobs.create!(
      title: "Festival",
      employment_type: :contract,
      posting_type: :multi_position,
      workplace_type: :on_site,
      status: :published,
      is_active: true,
      starts_at: Time.zone.parse("2026-08-10 08:00"),
      ends_at: Time.zone.parse("2026-08-12 18:00"),
      description: "Staff the festival."
    )
    position = job.crew_positions.create!(title: "Audio", headcount: 2)
    position.crew_assignments.create!(profile: available)
    position.crew_assignments.create!(profile: unavailable)
    unavailable.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "schedule-conflict",
      from_date: Time.zone.parse("2026-08-11 09:00"),
      to_date: Time.zone.parse("2026-08-11 17:00")
    )

    rows = JobCrewSchedule.new(job:).rows

    assert_not rows.find { |row| row.profile == available }.conflict?
    conflict = rows.find { |row| row.profile == unavailable }
    assert conflict.conflict?
    assert_equal "Unavailable Aug 11", conflict.availability_label
  end

  test "only reports conflicts on a job's selected work dates" do
    owner = create_user("tour-owner")
    profile = create_user("tour-worker").user_profile
    industry = Industry.create!(name: "Tour Schedule Industry")
    company = Company.create!(name: "Tour Schedule Company", contact_email: "tour-schedule@example.com", industries: [ industry ])
    company.company_assignments.create!(user: owner, role: "owner")
    job = company.jobs.create!(
      title: "Tour",
      employment_type: :contract,
      posting_type: :multi_position,
      workplace_type: :on_site,
      starts_at: Time.zone.parse("2026-09-01 08:00"),
      ends_at: Time.zone.parse("2026-12-31 18:00"),
      work_dates: [ Date.new(2026, 9, 5), Date.new(2026, 11, 14) ],
      description: "Staff selected tour stops."
    )
    job.crew_positions.create!(title: "Audio", headcount: 1).crew_assignments.create!(profile:)
    profile.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "between-tour-stops",
      from_date: Time.zone.parse("2026-10-10 09:00"),
      to_date: Time.zone.parse("2026-10-10 17:00")
    )
    profile.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "on-tour-stop",
      from_date: Time.zone.parse("2026-11-14 09:00"),
      to_date: Time.zone.parse("2026-11-14 17:00")
    )

    row = JobCrewSchedule.new(job:).rows.first

    assert_equal [ Date.new(2026, 11, 14) ], row.conflict_dates
  end

  test "summarizes long conflict lists instead of rendering every date in a badge" do
    conflict_dates = (Date.new(2026, 10, 1)..Date.new(2026, 10, 12)).to_a
    row = JobCrewSchedule::Row.new(position: nil, assignment: nil, profile: nil, conflict_dates:)

    assert_equal "Unavailable on 12 job dates", row.availability_label
  end

  private

  def create_user(label)
    user = User.create!(
      first_name: label.titleize,
      last_name: "Schedule",
      email: "#{label}-schedule@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end
end
