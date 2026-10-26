require "test_helper"
class AuthenticatedNavigationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []
  test "sign in persists a Devise session across requests without preloading route helpers" do
    user = User.create!(first_name: "Session", last_name: "Check", email: "session-check@example.com", password: "password123")
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    sign_in user, scope: :user
    get "/usr/network"
    assert_response :success
    assert_kind_of Array, session["warden.user.user.key"]
    assert_equal 2, session["warden.user.user.key"].size
    get "/usr/network"
    assert_response :success
  end
end
