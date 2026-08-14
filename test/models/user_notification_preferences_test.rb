require "test_helper"

class UserNotificationPreferencesTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "new users receive useful notification defaults" do
    user = User.create!(
      first_name: "New",
      last_name: "User",
      email: "new-user@example.com",
      password: "password123"
    )

    assert user.email_notifications_enabled?
    assert_not user.sms_notifications_enabled?
    assert user.job_alert_notifications_enabled?
    assert user.recommended_role_notifications_enabled?
    assert user.upcoming_job_reminder_notifications_enabled?
  end

  test "sms notifications require a phone number" do
    user = User.new(
      first_name: "Text",
      last_name: "User",
      email: "text-user@example.com",
      password: "password123",
      sms_notifications_enabled: true
    )

    assert_not user.valid?
    assert_includes user.errors[:phone], "can't be blank"
  end
end
