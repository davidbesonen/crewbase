require "test_helper"

class QuickStartTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @user = User.create!(first_name: "Quick", last_name: "Start", email: "quick@example.com", password: "password123")
    @profile = @user.profiles.create!(profile_type: "user")
    @user.assignments.create!(role: Role.find_or_create_by!(name: "user"))
    sign_in @user
  end

  test "new members get a short intent choice instead of the full profile wizard" do
    get usr_dashboards_path
    assert_redirected_to "/usr/onboarding"
    follow_redirect!
    assert_select "h1", text: "What brings you to KnowShow?"
    assert_select "input[name='onboarding[intent]']", count: 3
  end

  test "workers can find jobs before filling optional profile details" do
    occupation = Occupation.find_or_create_by!(name: "Audio Engineer")
    patch "/usr/onboarding", params: { onboarding: { intent: "find_work", occupation_ids: [ occupation.id ] } }
    assert_redirected_to usr_dashboards_path
    assert_equal [ occupation ], @profile.reload.occupations
    get usr_dashboards_path
    assert_response :success
    assert_select "[data-quick-start]", text: /Find your next role/
    assert_select ".workspace-sidenav a[href='#{usr_jobs_path}']"
    assert_select "a[href='#{usr_job_offers_path}']", text: "Offers & bookings"
    assert_nil @profile.completed_at
  end

  test "hirers go directly to company creation and can still open dashboard" do
    patch "/usr/onboarding", params: { onboarding: { intent: "hire_crew" } }
    assert_redirected_to new_usr_company_path
    get usr_dashboards_path
    assert_response :success
    assert_select "[data-quick-start]", text: /Post your first role/
  end

  test "invalid intent does not finish onboarding" do
    patch "/usr/onboarding", params: { onboarding: { intent: "invalid" } }
    assert_response :unprocessable_content
    assert_nil @user.reload.onboarding_completed_at
  end

  test "unfinished profiles stay out of the people directory" do
    get usr_profiles_path
    assert_select "a[href='#{usr_profile_path(@profile)}']", text: @user.full_name, count: 0
  end
end
