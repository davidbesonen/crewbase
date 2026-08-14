require "test_helper"

class Admin::UsersPageAuditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @admin = User.create!(
      first_name: "Admin",
      last_name: "Person",
      email: "admin-audit@example.com",
      password: "password123"
    )
    @admin.roles << Role.create!(name: "admin", pretty_name: "Admin")
    @member = User.create!(
      first_name: "Member",
      last_name: "Person",
      email: "member-audit@example.com",
      password: "password123"
    )
  end

  test "admin user index renders" do
    sign_in @admin, scope: :user

    get admin_users_path

    assert_response :success
    assert_select "h1", text: "Users"
    assert_select "td", text: @member.email
  end

  test "regular users cannot access admin user pages" do
    sign_in @member, scope: :user

    get admin_users_path

    assert_redirected_to usr_dashboards_path
  end
end
