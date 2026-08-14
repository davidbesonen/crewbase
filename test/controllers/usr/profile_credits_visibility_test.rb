require "test_helper"

class Usr::ProfileCreditsVisibilityTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    owner = User.create!(
      first_name: "Visible",
      last_name: "Credit",
      email: "visible-credit@example.com",
      password: "password123"
    )
    @profile = owner.profiles.create!(
      profile_type: "user",
      completed_at: Time.current,
      show_credits: true
    )
    @profile.credits.create!(
      role: "Camera Operator",
      project_name: "Documentary Day",
      starts_on: Date.new(2026, 7, 1)
    )
    viewer = User.create!(
      first_name: "Profile",
      last_name: "Viewer",
      email: "credit-viewer@example.com",
      password: "password123"
    )
    viewer.profiles.create!(profile_type: "user", completed_at: Time.current)
    sign_in viewer, scope: :user
  end

  test "profile displays credits when the user opts in" do
    get usr_profile_path(@profile)

    assert_response :success
    assert_select "#profile-credits" do
      assert_select ".profile-credits-heading.align-items-center" do
        assert_select "> .profile-credits-heading__icon > .crewbase-credit-badge"
        assert_select "> h5", text: "Crewbase Credits"
        assert_select "[data-profile-credit-count]", text: "1 credit earned"
      end
      assert_select ".crewbase-credit-badge-blue"
      assert_select "*", text: /Camera Operator/
      assert_select "*", text: /Documentary Day/
    end
  end

  test "profile hides credits when the user opts out" do
    @profile.update!(show_credits: false)

    get usr_profile_path(@profile)

    assert_response :success
    assert_select "#profile-credits", count: 0
  end

  test "profile hides an individually hidden credit from other users" do
    @profile.credits.first.update!(visible: false)

    get usr_profile_path(@profile)

    assert_response :success
    assert_select "#profile-credits", text: /Complete jobs through Crewbase/
    assert_select "#profile-credits", text: /Documentary Day/, count: 0
  end

  test "profile edit exposes a credits visibility option" do
    sign_in @profile.user, scope: :user

    get edit_usr_profile_path(@profile, source: "completed_profile")

    assert_response :success
    assert_select "input[name='profile[show_credits]']"
    assert_select "#credits_form"
  end
end
