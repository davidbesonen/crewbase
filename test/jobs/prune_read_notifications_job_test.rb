require "test_helper"

class PruneReadNotificationsJobTest < ActiveJob::TestCase
  self.fixture_table_names = []

  test "deletes notifications read more than 30 days ago and preserves everything else" do
    user = User.create!(
      first_name: "Notification",
      last_name: "Owner",
      email: "notification-owner@example.com",
      password: "password123"
    )
    expired = create_notification(user:, message: "Expired", read_at: 31.days.ago)
    retained = create_notification(user:, message: "Recent", read_at: 29.days.ago)
    unread_old = create_notification(user:, message: "Unread", read_at: nil, created_at: 1.year.ago)

    PruneReadNotificationsJob.perform_now

    assert_not Notification.exists?(expired.id)
    assert Notification.exists?(retained.id)
    assert Notification.exists?(unread_old.id)
  end

  test "runs daily in production" do
    recurring = YAML.safe_load_file(Rails.root.join("config/recurring.yml"), aliases: true)
    schedule = recurring.dig("production", "prune_read_notifications")

    assert_equal "PruneReadNotificationsJob", schedule.fetch("class")
    assert_equal "maintenance", schedule.fetch("queue")
    assert_equal "every day at 3:15am", schedule.fetch("schedule")
  end

  test "read retention has a partial read_at index" do
    index = Notification.connection.indexes(:notifications).find do |candidate|
      candidate.name == "index_notifications_on_read_at_for_retention"
    end

    assert_equal [ "read_at" ], index&.columns
    assert_equal "(read_at IS NOT NULL)", index&.where
  end

  private

  def create_notification(user:, message:, read_at:, created_at: Time.current)
    Notification.create!(
      recipient: user,
      kind: "system_update",
      message:,
      read_at:,
      created_at:,
      updated_at: created_at
    )
  end
end
