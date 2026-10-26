require "test_helper"

class ProfileExperienceSearchTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "MA3 search finds named aliases and legacy entries without treating a family as specific experience" do
    user = User.create!(first_name: "MA", last_name: "Search", email: "ma-search@example.com", password: "password123")
    named = user.profiles.create!(profile_type: "user", equipment_text: "grand MA 3 full-size")
    previous = user.profiles.create!(profile_type: "company_owner")
    previous.equipment << Equipment.create!(name: "grandMA3")
    family = user.profiles.create!(profile_type: "company_employee", equipment_family_keys: [ "lighting_consoles" ], equipment_text: "grandMA2\nMA30")
    scope = Profile.where(id: [ named.id, previous.id, family.id ])
    [ "MA3", "grandMA3", "MA 3" ].each do |query|
      assert_equal [ named.id, previous.id ].sort, ProfileExperienceSearch.new(scope:, equipment_query: query).results.ids.sort
    end
    previous.update!(equipment_text: "")
    assert_equal [ named.id ], ProfileExperienceSearch.new(scope:, equipment_query: "MA3").results.ids
  end

  test "search finds core work through occupations without inferring tools or other specialties" do
    user = User.create!(first_name: "Core", last_name: "Search", email: "core-search@example.com", password: "password123")
    profile = user.profiles.create!(profile_type: "user", occupations: [ Occupation.create!(name: "FOH Engineer") ])
    scope = Profile.where(id: profile.id)
    assert_equal [ profile.id ], ProfileExperienceSearch.new(scope:, skills_query: "Front-of-house mixing").results.ids
    assert_equal [ profile.id ], ProfileExperienceSearch.new(scope:, skills_query: "Audio production").results.ids
    assert_empty ProfileExperienceSearch.new(scope:, skills_query: "Monitor mixing").results
    assert_empty ProfileExperienceSearch.new(scope:, equipment_query: "Audio mixing consoles").results
  end

  test "searches personal entries and honors an explicitly cleared legacy entry" do
    user = User.create!(first_name: "Search", last_name: "Test", email: "personal-search@example.com", password: "password123")
    personal = user.profiles.create!(profile_type: "user", skills_text: "Rare workflow", equipment_text: "Special 100% console")
    legacy = user.profiles.create!(profile_type: "company_owner")
    legacy.skills << Skill.create!(name: "Rare workflow")
    scope = Profile.where(id: [ personal.id, legacy.id ])
    assert_equal [ personal.id, legacy.id ].sort, ProfileExperienceSearch.new(scope: scope, skills_query: "rare").results.ids.sort
    legacy.update!(skills_text: "")
    assert_equal [ personal.id ], ProfileExperienceSearch.new(scope: scope, skills_query: "rare").results.ids
    assert_empty ProfileExperienceSearch.new(scope: scope, equipment_query: "100_ console").results
    assert_equal [ personal.id ], ProfileExperienceSearch.new(scope: scope, equipment_query: "100% console").results.ids
    personal.update!(capability_keys: [ "audio" ], equipment_family_keys: [ "audio_systems" ])
    assert_equal [ personal.id ], ProfileExperienceSearch.new(scope: scope, skills_query: "Audio production").results.ids
    assert_equal [ personal.id ], ProfileExperienceSearch.new(scope: scope, equipment_query: "Audio systems").results.ids
    personal.update!(capability_keys: [ "monitor_mixing" ], equipment_family_keys: [ "mixing_consoles" ])
    assert_equal [ personal.id ], ProfileExperienceSearch.new(scope: scope, skills_query: "Audio production").results.ids
    assert_equal [ personal.id ], ProfileExperienceSearch.new(scope: scope, equipment_query: "Audio systems").results.ids
    assert_empty ProfileExperienceSearch.new(scope: scope, skills_query: "Front-of-house mixing").results
  end
end
