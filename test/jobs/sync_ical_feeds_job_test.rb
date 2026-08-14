require "test_helper"

class SyncIcalFeedsJobTest < ActiveJob::TestCase
  self.fixture_table_names = []

  test "enqueues a fetch for every connected profile" do
    connected_user = User.create!(
      first_name: "Connected",
      last_name: "Calendar",
      email: "connected-calendar@example.com",
      password: "password123"
    )
    connected = connected_user.profiles.create!(
      profile_type: "user",
      ical_feed_url: "https://calendar.example.com/feed.ics"
    )
    disconnected_user = User.create!(
      first_name: "Manual",
      last_name: "Calendar",
      email: "manual-calendar@example.com",
      password: "password123"
    )
    disconnected_user.profiles.create!(profile_type: "user")

    assert_enqueued_with(job: FetchIcalFeedJob, args: [ connected.id ]) do
      SyncIcalFeedsJob.perform_now
    end
  end
end
