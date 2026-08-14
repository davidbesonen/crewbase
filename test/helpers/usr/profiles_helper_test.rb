# frozen_string_literal: true

require "test_helper"

class Usr::ProfilesHelperTest < ActionView::TestCase
  self.fixture_table_names = []

  test "describes profiles less than a year old with relative time" do
    now = Time.zone.local(2026, 7, 24, 12)

    assert_equal "Joined 3 months ago", profile_joined_label(now - 3.months, now: now)
  end

  test "describes profiles at least a year old by join year" do
    now = Time.zone.local(2026, 7, 24, 12)

    assert_equal "Joined in 2022", profile_joined_label(Time.zone.local(2022, 10, 5), now: now)
    assert_equal "Joined in 2025", profile_joined_label(now - 1.year, now: now)
  end
end
