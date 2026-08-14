require "test_helper"

class Usr::SettingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "Jamie",
      last_name: "Rivera",
      email: "jamie@example.com",
      phone: "312-555-0198",
      password: "password123"
    )
    role = Role.create!(name: "user")
    @user.assignments.create!(role:)
    @profile = @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    sign_in @user, scope: :user
  end

  test "settings shows account information and notification preferences" do
    get usr_settings_path

    assert_response :success
    assert_select "h1", text: "Settings"
    assert_select ".row > .col-12 form[action='#{usr_settings_path}']"
    assert_select "form[action='#{usr_settings_path}']"
    assert_select "input[name='user[first_name]'][value='Jamie']"
    assert_select "input[name='user[email]'][value='jamie@example.com']"
    assert_select "input[name='user[email_notifications_enabled]']"
    assert_select "input[name='user[sms_notifications_enabled]']"
    assert_select "input[name='user[job_alert_notifications_enabled]']"
    assert_select "input[name='user[recommended_role_notifications_enabled]']"
    assert_select "input[name='user[upcoming_job_reminder_notifications_enabled]']"
    assert_select "a[href='#{usr_settings_billing_path}']", text: /Billing/
  end

  test "user updates account information and notification preferences" do
    patch usr_settings_path, params: {
      user: {
        first_name: "Jay",
        last_name: "Rivera",
        email: "jay@example.com",
        phone: "773-555-0100",
        email_notifications_enabled: "0",
        sms_notifications_enabled: "1",
        job_alert_notifications_enabled: "1",
        recommended_role_notifications_enabled: "0",
        upcoming_job_reminder_notifications_enabled: "1"
      }
    }

    assert_redirected_to usr_settings_path
    assert_equal "Settings updated.", flash[:notice]
    @user.reload
    assert_equal "Jay", @user.first_name
    assert_equal "jay@example.com", @user.email
    assert_equal "773-555-0100", @user.phone
    assert_not @user.email_notifications_enabled?
    assert @user.sms_notifications_enabled?
    assert @user.job_alert_notifications_enabled?
    assert_not @user.recommended_role_notifications_enabled?
    assert @user.upcoming_job_reminder_notifications_enabled?
  end

  test "settings re-renders errors when sms is enabled without a phone number" do
    patch usr_settings_path, params: {
      user: {
        first_name: "Jamie",
        last_name: "Rivera",
        email: "jamie@example.com",
        phone: "",
        sms_notifications_enabled: "1"
      }
    }

    assert_response :unprocessable_entity
    assert_select ".invalid-feedback", text: /Phone can't be blank/
    assert_not @user.reload.sms_notifications_enabled?
  end

  test "navbar and own profile link to settings" do
    get usr_profile_path(@profile)

    assert_response :success
    assert_select "a[href='#{usr_settings_path}']", text: /Settings/, minimum: 2
  end

  test "settings requires authentication" do
    sign_out @user

    get usr_settings_path

    assert_redirected_to new_user_session_path
  end
end
