require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    Role.find_or_create_by!(name: "user")
  end

  test "new account starts profile configuration" do
    assert_difference [ "User.count", "Profile.count" ], 1 do
      post user_registration_path, params: {
        user: {
          first_name: "New",
          last_name: "Member",
          email: "new-member@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    user = User.find_by!(email: "new-member@example.com")
    profile = user.profiles.find_by!(profile_type: "user")

    assert_redirected_to edit_usr_profile_path(profile)
    assert user.has_role?("user")
  end

  test "new member can traverse every profile configuration action" do
    user = User.create!(
      first_name: "Workflow",
      last_name: "Tester",
      email: "workflow-tester@example.com",
      password: "password123"
    )
    profile = user.profiles.create!(profile_type: "user")
    occupation = Occupation.create!(name: "Workflow Occupation")
    skill = Skill.create!(name: "Workflow Skill", occupations: [ occupation ])
    equipment = Equipment.create!(name: "Workflow Equipment", occupations: [ occupation ])
    sign_in user, scope: :user

    get edit_usr_profile_path(profile)
    assert_response :success
    assert_select "button", text: /Industry & Occupation/

    patch usr_profile_path(profile), params: {
      current_page: "location_form",
      profile: {
        locations_attributes: {
          "0" => { city: "Chicago", state: "Illinois", country: "United States" }
        }
      }
    }, as: :turbo_stream
    assert_response :success
    assert_includes response.body, 'target="occupation_form"'

    get toggle_occupation_selection_usr_profile_path(profile),
      params: { occupation_id: occupation.id },
      as: :turbo_stream
    assert_response :success

    get next_page_usr_profile_path(profile),
      params: { current_page: "occupation_form" },
      as: :turbo_stream
    assert_response :success
    assert_includes response.body, 'target="skill_equipment_form"'

    get toggle_skill_selection_usr_profile_path(profile),
      params: { skill_id: skill.id },
      as: :turbo_stream
    assert_response :success

    get toggle_equipment_selection_usr_profile_path(profile),
      params: { equipment_id: equipment.id },
      as: :turbo_stream
    assert_response :success

    patch usr_profile_path(profile), params: {
      current_page: "skill_equipment_form",
      profile: { website_url: "" }
    }, as: :turbo_stream
    assert_response :success
    assert_includes response.body, 'target="availability_form"'

    blockout_date = 1.week.from_now.to_date
    get toggle_date_selection_usr_profile_calendar_events_path(profile),
      params: {
        date: blockout_date.iso8601,
        month: blockout_date.beginning_of_month.iso8601,
        toggle_action: "add"
      },
      as: :turbo_stream
    assert_response :success

    get edit_usr_profile_path(profile, current_page: "online_presence_form")
    assert_response :success

    patch usr_profile_path(profile), params: {
      current_page: "online_presence_form",
      profile: { website_url: "https://example.com" }
    }
    assert_redirected_to usr_dashboards_path
    assert profile.reload.completed_at.present?
  end
end
