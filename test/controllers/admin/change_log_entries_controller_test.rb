require "test_helper"

class Admin::ChangeLogEntriesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @admin = User.create!(
      first_name: "Admin",
      last_name: "User",
      email: "admin-changelog@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    role = Role.create!(name: "admin")
    @admin.assignments.create!(role:)
    sign_in @admin, scope: :user
  end

  test "admin can publish a plain-language update" do
    assert_difference "ChangeLogEntry.count", 1 do
      post admin_change_log_entries_path, params: {
        change_log_entry: {
          title: "Easier job invitations",
          summary: "Send a posting directly by email or copy a shareable link.",
          published_at: Time.current
        }
      }
    end

    assert_redirected_to admin_change_log_entries_path
    assert ChangeLogEntry.last.published?
  end
end
