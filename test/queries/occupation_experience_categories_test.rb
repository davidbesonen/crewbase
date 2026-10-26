require "test_helper"
require Rails.root.join("db/catalogs/occupations_v2")

class OccupationExperienceCategoriesTest < ActiveSupport::TestCase
  test "distinguishes adjacent jobs instead of giving everyone department-wide skills" do
    examples = {
      "FOH Engineer" => [ "system_tuning", "mastering" ],
      "Monitor Engineer" => [ "rf_coordination", "mastering" ],
      "Audio Systems Engineer" => [ "rf_coordination", "studio_recording" ],
      "Lighting Programmer" => [ "lighting_design", "lighting_programming" ],
      "Camera Operator" => [ "camera_shading", "color_grading" ],
      "Musical Director" => [ "live_playback", "mastering" ],
      "Rigger" => [ "staging", "suspended_rigging" ],
      "Show Caller" => [ "rehearsal_management", "lighting_programming" ],
      "Tour Accountant" => [ "tour_logistics", "rights_administration" ],
      "Merchandise Manager" => [ "tour_logistics", "show_calling" ]
    }
    examples.each do |name, (relevant, irrelevant)|
      keys = OccupationExperienceCategories.new([ Occupation.new(name:) ]).keys.fetch("Skill")
      assert_includes keys, relevant, name
      assert_not_includes keys, irrelevant, name
    end
  end
  test "tailors categories to occupations and combines multiple roles" do
    audio = Occupation.new(name: "FOH Engineer")
    camera = Occupation.new(name: "Camera Operator")
    keys = OccupationExperienceCategories.new([ audio ]).keys
    assert_not_includes keys.fetch("Skill"), "audio"
    assert_not_includes keys.fetch("Skill"), "foh_mixing"
    assert_includes keys.fetch("Equipment"), "mixing_consoles"
    assert_not_includes keys.fetch("Equipment"), "broadcast_cameras"
    combined = OccupationExperienceCategories.new([ audio, camera ]).keys
    assert_includes combined.fetch("Equipment"), "broadcast_cameras"
    assert_includes combined.fetch("Equipment"), "mixing_consoles"
  end

  test "maintained occupations have valid guidance without classifying unknown roles" do
    TouringCatalog.occupation_names.each do |name|
      keys = OccupationExperienceCategories.new([ Occupation.new(name:) ]).keys
      keys.each do |type, values|
        assert values.any?, "Missing #{type} guidance for #{name}"
        assert_empty values - ExperienceCategories.all(type).map(&:key)
        assert_equal ExperienceCategories.most_specific(type, values), values, "Redundant parent for #{name}"
      end
      core = OccupationExperienceCategories.new([ Occupation.new(name:) ]).core_keys
      assert core.any?, "Missing core review for #{name}"
      assert_empty core & keys.fetch("Skill"), "Core work offered as an extra for #{name}"
    end
    assert_equal({ "Skill" => [], "Equipment" => [] }, OccupationExperienceCategories.new([ Occupation.new(name: "New specialty") ]).keys)
  end
end
