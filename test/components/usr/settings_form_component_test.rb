require "test_helper"

class Usr::SettingsFormComponentTest < ViewComponent::TestCase
  test "settings controls have one readable label each" do
    user = User.new(first_name: "Crew", last_name: "Member", email: "member@example.com")
    render_inline Usr::SettingsFormComponent.new(user:)

    %w[first_name last_name email phone email_notifications_enabled sms_notifications_enabled
       job_alert_notifications_enabled recommended_role_notifications_enabled upcoming_job_reminder_notifications_enabled].each do |field|
      assert_selector "label[for='user_#{field}']", count: 1
    end
    assert_selector "label[for='user_phone']", text: "Phone number"
    assert_selector "input#user_sms_notifications_enabled[disabled]"
    assert_text "SMS delivery is not available"
    assert_selector "a[href='/usr/reports']", text: "Reports & blocked people"
    assert_selector "a[href='/usr/onboarding']", text: "Change my goals"
  end
end
