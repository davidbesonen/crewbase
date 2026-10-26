require "test_helper"

class Users::AccountPageAuditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  test "public authentication pages render" do
    get new_user_session_path
    assert_response :success
    assert_select "h2", text: "Log In"

    get new_user_registration_path
    assert_response :success
    assert_select "h2", text: "Sign Up"

    get new_user_password_path
    assert_response :success
    assert_select "h2", text: "Forgot Your Password?"

    get edit_user_password_path(reset_password_token: "invalid-token")
    assert_response :success
    assert_select "h2", text: "Change Your Password"
  end

  test "account edit page renders for a signed in user" do
    user = User.create!(
      first_name: "Account",
      last_name: "Owner",
      email: "account-owner@example.com",
      password: "password123"
    )
    sign_in user, scope: :user

    get edit_user_registration_path

    assert_response :success
    assert_select "form[action='#{user_registration_path}']"
  end

  test "marketing homepage and health check remain public while dashboard requires authentication" do
    get root_path
    assert_response :success
    assert_select "[data-marketing-homepage]"

    get usr_dashboards_path
    assert_redirected_to new_user_session_path

    get rails_health_check_path
    assert_response :success
  end
end
