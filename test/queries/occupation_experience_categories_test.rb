require "test_helper"
require Rails.root.join("db/catalogs/occupations_v2")

class OccupationExperienceCategoriesTest < ActiveSupport::TestCase
  test "distinguishes adjacent jobs instead of giving everyone department-wide skills" do
    examples = {
      "FOH Engineer" => [ "system_tuning", "mastering" ],
      "Monitor Engineer" => [ "rf_coordination", "mastering" ],
      "Audio Systems Engineer" => [ "rf_coordination", "studio_recording" ],
      "Mastering Engineer" => [ "audio_editing", "monitor_mixing" ],
      "First Assistant Camera" => [ "camera_operation", "color_grading" ],
      "Digital Imaging Technician" => [ "camera_shading", "motion_graphics" ],
      "Graphics Operator" => [ "motion_graphics", "scenic_design" ],
      "Key Grip" => [ "staging", "suspended_rigging" ],
      "Show Caller" => [ "rehearsal_management", "lighting_programming" ],
      "Catalog Manager" => [ "rights_administration", "studio_recording" ],
      "Instructor" => [ "instructional_design", "show_calling" ]
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
    assert_not_includes keys.fetch("Equipment"), "cinema_cameras"
    combined = OccupationExperienceCategories.new([ audio, camera ]).keys
    assert_includes combined.fetch("Equipment"), "cinema_cameras"
    assert_includes combined.fetch("Equipment"), "mixing_consoles"
  end

  test "maintained occupations have valid guidance without classifying unknown roles" do
    OccupationsV2::BY_INDUSTRY.values.flatten.uniq.each do |name|
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
