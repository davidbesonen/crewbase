require "test_helper"

class ProfileFormCatalogTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "does not require occupation links for selected legacy experience" do
    user = User.create!(
      first_name: "Query",
      last_name: "Tester",
      email: "profile-form-catalog@example.com",
      password: "password123"
    )
    profile = user.profiles.create!(profile_type: "user")
    occupation = Occupation.create!(name: "Catalog Audio Engineer")
    other_occupation = Occupation.find_or_create_by!(name: "Lighting Designer")
    matching_skill = Skill.create!(name: "Catalog Mixing")
    Skill.create!(name: "Catalog Rigging").occupations << other_occupation
    matching_equipment = Equipment.create!(name: "Catalog Console")
    Equipment.create!(name: "Catalog Lighting Desk").occupations << other_occupation
    matching_skill.occupations << occupation
    matching_equipment.occupations << occupation
    profile.occupations << occupation
    profile.skills << matching_skill
    profile.equipment << matching_equipment

    catalog = ProfileFormCatalog.new(profile)

    assert_equal [ occupation ], catalog.profile_occupations.to_a
    assert_includes catalog.occupations, occupation
    assert_includes catalog.occupations, other_occupation
  end
end
