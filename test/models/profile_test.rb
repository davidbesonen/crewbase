require "test_helper"

class ProfileTest < ActiveSupport::TestCase
  test "accepts published Google and Outlook calendar subscription feeds" do
    google = Profile.new(ical_feed_url: "https://calendar.google.com/calendar/ical/private/basic.ics")
    outlook = Profile.new(ical_feed_url: "https://outlook.office365.com/owa/calendar/id/calendar.ics")

    google.validate
    outlook.validate

    assert_empty google.errors[:ical_feed_url]
    assert_empty outlook.errors[:ical_feed_url]
  end

  test "rejects unsafe calendar feed URLs" do
    profile = Profile.new(ical_feed_url: "http://127.0.0.1/private.ics")

    assert_not profile.valid?
    assert_includes profile.errors[:ical_feed_url], "must be a public HTTP or HTTPS URL"
  end

  self.fixture_table_names = []

  test "has many calendar events" do
    association = Profile.reflect_on_association(:calendar_events)

    assert_not_nil association
    assert_equal :has_many, association.macro
  end

  test "profile completion awards useful increments for each profile section" do
    user = User.create!(
      first_name: "Profile",
      last_name: "Progress",
      email: "profile-progress@example.com",
      password: "password123"
    )
    profile = user.profiles.create!(profile_type: "user")

    assert_equal 0, profile.completion_percentage
    assert_equal :location, profile.next_completion_step.fetch(:key)

    profile.locations << Location.create!(city: "Chicago", state: "IL", country: "United States")
    assert_equal 15, profile.completion_percentage

    profile.occupations << Occupation.create!(name: "Dashboard Audio Engineer")
    assert_equal 35, profile.completion_percentage

    profile.skills << Skill.create!(name: "Dashboard Mixing")
    assert_equal 50, profile.completion_percentage

    profile.update!(bio: "Experienced production professional.")
    assert_equal 65, profile.completion_percentage

    profile.experiences.create!(title: "Audio Engineer", company_name: "Crewbase")
    assert_equal 80, profile.completion_percentage

    profile.update!(website_url: "https://example.com")
    assert_equal 90, profile.completion_percentage

    profile.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "dashboard-progress",
      from_date: 1.week.from_now,
      to_date: 1.week.from_now
    )

    assert_equal 100, profile.completion_percentage
    assert profile.complete?
    assert_nil profile.next_completion_step
  end

  test "availability overview reports upcoming blocked dates and calendar connection" do
    user = User.create!(
      first_name: "Available",
      last_name: "Person",
      email: "availability-overview@example.com",
      password: "password123"
    )
    profile = user.profiles.create!(profile_type: "user", ical_feed_url: "https://example.com/calendar.ics")
    profile.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "dashboard-availability",
      from_date: 3.days.from_now,
      to_date: 3.days.from_now
    )

    overview = profile.availability_overview

    assert_equal "Calendar connected", overview.fetch(:status)
    assert_equal 1, overview.fetch(:blocked_days)
    assert_equal 3.days.from_now.to_date, overview.fetch(:next_blockout_date)
  end
end
