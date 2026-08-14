require "test_helper"

class Usr::UserSidenavProjectsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "Sidebar",
      last_name: "Owner",
      email: "sidebar-projects@example.com",
      password: "password123"
    )
    @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @user.visits.create!
    @user.assignments.create!(role: Role.create!(name: "user"))
    sign_in @user, scope: :user
  end

  test "company owner sees projects linked to their company" do
    industry = Industry.create!(name: "Sidebar Projects")
    company = Company.create!(
      name: "Sidebar Productions",
      contact_email: "sidebar-productions@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: @user, role: "owner")

    get usr_dashboards_path

    assert_response :success
    assert_select "a[href='#{usr_company_projects_path(company)}']", text: /Projects/
  end

  test "user without an owned company does not see projects navigation" do
    get usr_dashboards_path

    assert_response :success
    assert_select "a", text: "Projects", count: 0
  end

  test "sidebar links to the invitations index" do
    get usr_dashboards_path

    assert_response :success
    assert_select ".user-sidenav-card a[href='/usr/job_invitations']", text: /Invitations/, minimum: 1
  end
end
