require "test_helper"

class Users::SessionsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  test "invalid credentials render the login page instead of raising" do
    User.create!(
      first_name: "Session",
      last_name: "User",
      email: "session-user@example.com",
      password: "password123"
    )

    assert_no_difference "Visit.count" do
      post user_session_path, params: {
        user: { email: "session-user@example.com", password: "incorrect" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h2", text: "Log in"
  end
end
