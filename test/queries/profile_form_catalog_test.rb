require "test_helper"

class ProfileFormCatalogTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "returns ordered skills and equipment relevant to the profile occupations" do
    user = User.create!(
      first_name: "Query",
      last_name: "Tester",
      email: "profile-form-catalog@example.com",
      password: "password123"
    )
    profile = user.profiles.create!(profile_type: "user")
    occupation = Occupation.create!(name: "Catalog Audio Engineer")
    other_occupation = Occupation.create!(name: "Catalog Lighting Designer")
    matching_skill = Skill.create!(name: "Catalog Mixing")
    Skill.create!(name: "Catalog Rigging").occupations << other_occupation
    matching_equipment = Equipment.create!(name: "Catalog Console")
    Equipment.create!(name: "Catalog Lighting Desk").occupations << other_occupation
    matching_skill.occupations << occupation
    matching_equipment.occupations << occupation
    profile.occupations << occupation

    catalog = ProfileFormCatalog.new(profile)

    assert_equal [ occupation ], catalog.profile_occupations.to_a
    assert_equal [ matching_skill ], catalog.skills.to_a
    assert_equal [ matching_equipment ], catalog.equipment.to_a
  end
end
