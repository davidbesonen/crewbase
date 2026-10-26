require "application_system_test_case"

class OccupationExperienceTest < ApplicationSystemTestCase
  include Warden::Test::Helpers
  self.fixture_table_names = []

  test "changing occupations updates guidance and preserves unsaved experience" do
    user = User.create!(first_name: "Experience", last_name: "Test", email: "experience-system@example.com", password: "password123")
    camera = Occupation.create!(name: "Camera Operator")
    audio = Occupation.create!(name: "FOH Engineer")
    profile = user.profiles.create!(profile_type: "user", completed_at: Time.current, occupations: [ camera ])
    user.visits.create!
    login_as user, scope: :user

    visit edit_usr_profile_path(profile, source: "completed_profile")
    assert_no_selector "input[value='camera_operation']"
    assert_selector "[data-category-core-summary]", text: "Camera operation & composition"
    assert_selector "[data-category-primary] input[value='cinematic_lighting']"
    fill_in "profile_skills_text", with: "Unsaved camera setup notes"
    check "profile_capability_keys_cinematic_lighting"
    fill_in "occupation_search", with: "FOH Engineer"
    find("[role='option']", text: "FOH Engineer").click
    assert_selector "[data-category-core-summary]", text: "Front-of-house mixing"
    assert_no_selector "input[value='foh_mixing']"
    fill_in "occupation_search", with: "Camera Operator"
    find("[role='option']", text: "Camera Operator").click
    assert_selector "[data-category-primary] input[value='cinematic_lighting']:checked"
    assert_no_selector "[data-category-core-summary]", text: "Camera operation & composition"
    assert_field "profile_skills_text", with: "Unsaved camera setup notes"
    assert_selector "[data-category-primary] input[value='mixing_consoles']"
    assert_selector "[data-category-other] input[value='cinema_cameras']", visible: :all
    assert_empty profile.reload.capability_keys
    assert_equal [ audio.id ], profile.occupation_ids
  ensure
    Warden.test_reset!
  end
end
