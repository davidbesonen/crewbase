require "test_helper"

class Usr::ProfileRouteAuditTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "Route",
      last_name: "Auditor",
      email: "profile-route-auditor@example.com",
      password: "password123"
    )
    @profile = @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @user.visits.create!
    sign_in @user, scope: :user
  end

  test "people search matches a person's full name" do
    matching_user = User.create!(
      first_name: "David",
      last_name: "Besonen",
      email: "full-name-search@example.com",
      password: "password123"
    )
    matching_user.profiles.create!(profile_type: "user", completed_at: Time.current)
    other_user = User.create!(
      first_name: "David",
      last_name: "Different",
      email: "other-full-name-search@example.com",
      password: "password123"
    )
    other_user.profiles.create!(profile_type: "user", completed_at: Time.current)

    get usr_profiles_path, params: { q: { user_first_name_or_user_last_name_cont: "David Besonen" } }

    assert_response :success
    assert_select "h4", text: "David Besonen"
    assert_select "h4", text: "David Different", count: 0
  end

  test "a user cannot edit another person's profile" do
    other_user = User.create!(
      first_name: "Other",
      last_name: "Person",
      email: "other-profile@example.com",
      password: "password123"
    )
    other_profile = other_user.profiles.create!(profile_type: "user", completed_at: Time.current)

    get edit_usr_profile_path(other_profile)

    assert_response :not_found
  end

  test "profile routes do not expose unimplemented controller actions" do
    profile_actions = Rails.application.routes.routes.filter_map do |route|
      requirements = route.requirements
      requirements[:action] if requirements[:controller] == "usr/profiles"
    end

    assert_empty profile_actions & %w[new create destroy]
  end

  test "routes do not point to the removed location search controller" do
    location_routes = Rails.application.routes.routes.select do |route|
      route.requirements[:controller] == "usr/locations"
    end

    assert_empty location_routes
  end
end
