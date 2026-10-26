require "test_helper"

class ExperienceCategorySuggestionsTest < ActiveSupport::TestCase
  test "suggestions do not reintroduce core work or retired equipment umbrellas" do
    profile = Profile.new(occupations: [ Occupation.new(name: "Actor") ], skills_text: "Acting", equipment_text: "Audio systems")
    assert_empty ExperienceCategorySuggestions.new(profile:).results
  end

  test "offers meaningful specialties without redundant parents or automatic confirmation" do
    profile = Profile.new(skills_text: "Live sound mixing", equipment_text: "Mixing consoles")
    suggestions = ExperienceCategorySuggestions.new(profile:).results
    assert_includes suggestions.map { |entry| entry.category.key }, "foh_mixing"
    assert_includes suggestions.map { |entry| entry.category.key }, "mixing_consoles"
    assert_not_includes suggestions.map { |entry| entry.category.key }, "audio"
    assert_not_includes suggestions.map { |entry| entry.category.key }, "audio_systems"
    assert_empty profile.capability_keys
    assert_empty profile.equipment_family_keys
  end
end
