require "test_helper"

class Admin::DashboardAndIndexesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @admin = create_user("admin-product@example.com", "Admin", "Operator")
    @admin.roles << Role.create!(name: "admin", pretty_name: "Admin")
    @member = create_user("member-product@example.com", "Regular", "Member")
    industry = Industry.create!(name: "Administration")
    @company = Company.create!(name: "Admin Company", contact_email: "admin-company@example.com", industries: [ industry ])
    CompanyAssignment.create!(company: @company, user: @member, role: "owner")
    @job = Job.create!(company: @company, title: "Admin Job", workplace_type: :remote,
      employment_type: :contract, status: :published, description: "Run the show")
  end

  test "admin dashboard presents honest operating metrics and trend data" do
    @member.visits.create!(created_at: Time.current)
    sign_in @admin, scope: :user

    get admin_root_path

    assert_response :success
    assert_select "h1", text: "Admin Dashboard"
    assert_select "[data-metric='users'] .display-6"
    assert_select "[data-metric='companies'] .display-6"
    assert_select "[data-metric='jobs'] .display-6"
    assert_select "canvas[data-controller='admin-chart']"
    assert_select "h2", text: /Sign-ins over time/
  end

  test "admin can browse paginated users companies and jobs" do
    sign_in @admin, scope: :user

    { admin_users_path => @member.email, admin_companies_path => @company.name, admin_jobs_path => @job.title }.each do |path, text|
      get path
      assert_response :success
      assert_select "table", text: /#{Regexp.escape(text)}/
    end
  end

  test "regular member cannot access any admin operations page" do
    sign_in @member, scope: :user

    [ admin_root_path, admin_users_path, admin_companies_path, admin_jobs_path ].each do |path|
      get path
      assert_redirected_to usr_dashboards_path
    end
  end

  test "admin navigation marks the current section including nested screens" do
    sign_in @admin, scope: :user

    { admin_root_path => admin_root_path, admin_users_path => admin_users_path,
      admin_companies_path => admin_companies_path, admin_jobs_path => admin_jobs_path,
      new_admin_change_log_entry_path => admin_change_log_entries_path }.each do |path, navigation_path|
      get path

      assert_response :success
      assert_select ".app-top-nav a[aria-current='page']", count: 1
      assert_select ".app-top-nav a.active[aria-current='page'][href='#{navigation_path}']", count: 1
    end
  end

  private

  def create_user(email, first_name, last_name)
    User.create!(email:, first_name:, last_name:, password: "password123", password_confirmation: "password123")
  end
end
