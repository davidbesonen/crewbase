# frozen_string_literal: true

require "test_helper"

class Usr::ProfileConfig::AvailabilityFormComponentTest < ViewComponent::TestCase
  self.fixture_table_names = []

  FakeCalendarEvents = Struct.new(:records) do
    def where(...)
      self
    end

    def pluck(...)
      records
    end
  end

  FakeProfile = Struct.new(:id, :ical_feed_url, :ical_last_synced_at, :calendar_events, :completed_at) do
    def to_param
      id.to_s
    end
  end

  test "completed profile mode renders a calendar management link instead of nested sync form" do
    profile = FakeProfile.new(42, nil, nil, FakeCalendarEvents.new([]))

    result = render_inline(
      Usr::ProfileConfig::AvailabilityFormComponent.new(
        profile: profile,
        show_navigation: false,
        show_embedded_sync_form: false
      )
    )

    assert_includes result.to_html, "Manage Calendar Sync"
    assert_no_match(/update_calendar/, result.to_html)
  end

  test "embedded sync controls submit through the parent profile form" do
    profile = FakeProfile.new(42, nil, nil, FakeCalendarEvents.new([]))

    result = render_inline(
      Usr::ProfileConfig::AvailabilityFormComponent.new(
        profile: profile,
        show_navigation: false,
        show_embedded_sync_form: true,
        embedded_in_profile_form: true
      )
    )

    assert_includes result.to_html, 'name="profile[ical_feed_url]"'
    assert_includes result.to_html, 'formaction="/usr/profiles/42/update_calendar"'
    assert_includes result.to_html, 'name="_method"'
    assert_includes result.to_html, 'value="patch"'
    assert_no_match(/<form[^>]*update_calendar/, result.to_html)
  end

  test "calendar sync explains supported subscription feeds" do
    profile = FakeProfile.new(42, nil, nil, FakeCalendarEvents.new([]))

    result = render_inline(
      Usr::ProfileConfig::AvailabilityFormComponent.new(
        profile: profile,
        show_navigation: false,
        show_embedded_sync_form: true,
        embedded_in_profile_form: true
      )
    )

    assert_includes result.to_html, "Google, Outlook, or Apple"
    assert_includes result.to_html, "ICS subscription link"
  end

  test "completed profile calendar renders only a back to profile button" do
    profile = FakeProfile.new(42, nil, nil, FakeCalendarEvents.new([]))

    result = render_inline(
      Usr::ProfileConfig::AvailabilityFormComponent.new(
        profile: profile,
        show_embedded_sync_form: false,
        show_completed_profile_navigation: true
      )
    )

    assert_includes result.to_html, "Back to Profile"
    assert_includes result.to_html, 'href="/usr/profiles/42"'
    assert_not_includes result.to_html, "Skills &amp; Services"
    assert_not_includes result.to_html, "Online Presence"
  end
end
