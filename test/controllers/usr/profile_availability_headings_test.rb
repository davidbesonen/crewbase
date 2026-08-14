require "test_helper"

class Usr::ProfileAvailabilityHeadingsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "David",
      last_name: "Availability",
      email: "david.availability@example.com",
      password: "password123"
    )
    @profile = @user.profiles.create!(profile_type: "user")
    sign_in @user, scope: :user
  end

  test "first-time profile setup uses onboarding availability headings" do
    get edit_calendar_usr_profile_path(@profile, month: "2026-07-01")

    assert_response :success
    assert_select "h1", text: "Welcome David 👋"
    assert_select "h4", text: "Tell us about yourself..."
    assert_select "h4", text: "What is your availability for the next year?"
  end

  test "completed profile uses availability management headings" do
    @profile.update!(completed_at: Time.current)

    get edit_calendar_usr_profile_path(@profile, month: "2026-07-01")

    assert_response :success
    assert_select "h1", text: "Manage Availability"
    assert_select "h4", text: "Update Availability"
    assert_select "h1", text: /Welcome David/, count: 0
    assert_select "h4", text: "What is your availability for the next year?", count: 0
  end
end
