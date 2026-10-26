require "test_helper"

class Admin::OperationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @user = User.create!(first_name: "Ops", last_name: "Admin", email: "ops-admin@example.com", password: "password123")
    @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    sign_in @user
  end

  test "operations is restricted to administrators" do
    get "/admin/operations"
    assert_redirected_to usr_dashboards_path
  end

  test "administrators see delivery status and provider readiness" do
    @user.roles << Role.create!(name: "admin")
    get "/admin/operations"
    assert_response :success
    assert_select "h1", text: "Operations"
    assert_select "h2", text: "Notification delivery"
    assert_select "body", text: /Backup restoration/
  end
end
