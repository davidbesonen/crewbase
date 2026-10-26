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
    @profile = @user.profiles.create!(profile_type: "user", completed_at: Time.current)
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

  test "dashboard is current in both desktop and mobile navigation" do
    get usr_dashboards_path

    assert_current_navigation usr_dashboards_path
    assert_select ".app-top-nav a.navbar-brand[href='#{usr_dashboards_path}']", count: 1
  end

  test "desktop and mobile sidebars group navigation into labelled landmarks" do
    get usr_dashboards_path

    assert_response :success
    assert_select ".user-sidenav-card", count: 2 do |sidebars|
      sidebars.each do |sidebar|
        assert_select sidebar, "nav[aria-label='Workspace'] a[href='#{usr_jobs_path}']"
        assert_select sidebar, "nav[aria-label='Network'] a[href='#{usr_profiles_path}']"
        assert_select sidebar, "nav[aria-label='Inbox'] a[href='#{usr_conversations_path}']"
        assert_select sidebar, "nav[aria-label='Your companies'] a[href='#{new_usr_company_path}']"
        assert_select sidebar, "nav[aria-label='Account'] a[href='#{usr_settings_path}']"
        assert_select sidebar, "i:not([aria-hidden='true'])", count: 0
      end
    end
  end

  test "mobile navigation drawer has a visible accessible title" do
    get usr_dashboards_path

    assert_select "#userSidenav[aria-labelledby='userSidenavLabel']" do
      assert_select "#userSidenavLabel", text: "Your Workspace"
      assert_select "button[aria-label='Close navigation']"
    end
  end

  test "settings links to the account screen and stays current on billing" do
    [ usr_settings_path, usr_settings_billing_path ].each do |path|
      get path

      assert_current_navigation usr_settings_path
      assert_select ".user-sidenav-card a[href='#']", text: /Settings/, count: 0
    end
  end

  test "own profile and availability select My Profile without selecting People" do
    [ usr_profile_path(@profile), edit_calendar_usr_profile_path(@profile) ].each do |path|
      get path

      assert_current_navigation usr_profile_path(@profile)
    end
  end

  test "another person's profile selects People" do
    person = User.create!(first_name: "Other", last_name: "Person", email: "other-navigation@example.com", password: "password123")
    profile = person.profiles.create!(profile_type: "user", completed_at: Time.current)

    get usr_profile_path(profile)

    assert_current_navigation usr_profiles_path
  end

  test "saved jobs remain in the Jobs section" do
    get usr_saved_jobs_path

    assert_current_navigation usr_jobs_path
  end

  test "company management selects its company and projects select Projects" do
    company = Company.create!(name: "Navigation Company", contact_email: "navigation@example.com", industries: [ Industry.create!(name: "Navigation") ])
    company.company_assignments.create!(user: @user, role: "owner")

    get usr_company_plan_path(company)
    assert_current_navigation usr_company_path(company)

    get usr_company_projects_path(company)
    assert_current_navigation usr_company_projects_path(company)
  end

  private

  def assert_current_navigation(path)
    assert_response :success
    assert_select ".user-sidenav-card", count: 2 do |sidebars|
      sidebars.each do |sidebar|
        assert_select sidebar, "a[aria-current='page']", count: 1
        assert_select sidebar, "a.active[aria-current='page'][href='#{path}']", count: 1
      end
    end
  end
end
