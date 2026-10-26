require "test_helper"
require Rails.root.join("db/catalogs/experience_v1")

class ExperienceCategoriesTest < ActiveSupport::TestCase
  test "offers practical work specialties without losing any existing category" do
    assert_includes ExperienceCategories.all("Skill").map(&:key), "monitor_mixing"
    assert_includes ExperienceCategories.all("Equipment").map(&:key), "color_grading_software"
    ExperienceCategories::GROUPS.each do |type, group|
      old_keys = ExperienceV1::ENTRIES.fetch(group).keys
      assert_empty old_keys - ExperienceCategories.all(type).map(&:key)
    end
  end

  test "specialty confirms its broad family but broad familiarity never confirms a specialty" do
    assert ExperienceCategories.covers?("Skill", [ "foh_mixing" ], "audio")
    assert_not ExperienceCategories.covers?("Skill", [ "audio" ], "foh_mixing")
    assert_not ExperienceCategories.covers?("Skill", [ "foh_mixing" ], "monitor_mixing")
    assert ExperienceCategories.covers?("Equipment", [ "mixing_consoles" ], "audio_systems")
  end

  test "catalog keys and parent links stay valid and never cycle" do
    ExperienceCategories::CATALOG.each_key do |type|
      categories = ExperienceCategories.all(type)
      assert_equal categories.map(&:name).uniq.size, categories.size
      categories.each do |category|
        assert_match(/\A[a-z][a-z0-9_]+\z/, category.key)
        assert category.description.present?
        if category.broader
          assert_includes categories.map(&:key), category.broader
          assert_not ExperienceCategories.covers?(type, [ category.broader ], category.key)
        end
      end
    end
  end
end
