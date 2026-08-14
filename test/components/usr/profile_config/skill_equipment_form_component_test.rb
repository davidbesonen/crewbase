# frozen_string_literal: true

require "test_helper"

class Usr::ProfileConfig::SkillEquipmentFormComponentTest < ViewComponent::TestCase
  FakeProfile = Struct.new(:id) do
    def to_param
      id.to_s
    end
  end

  FakeOccupation = Struct.new(:id, :name)

  FakeItem = Struct.new(:id, :name, :industry_names_text, :occupation_names_text, :item_occupations) do
    def industries
      []
    end

    def occupations
      item_occupations || []
    end
  end

  test "renders skills and equipment grouped by selected occupation labels only when items exist" do
    profile = FakeProfile.new(42)
    audio_engineer = FakeOccupation.new(1, "Audio Engineer")
    lighting_designer = FakeOccupation.new(2, "Lighting Designer")
    stage_manager = FakeOccupation.new(3, "Stage Manager")
    selected_skill = FakeItem.new(1, "Lighting Design", "Live Events", "Lighting Designer", [ lighting_designer ])
    available_skill = FakeItem.new(2, "Audio Mixing", "", "", [ audio_engineer ])
    selected_equipment = FakeItem.new(3, "Stage Console", "Broadcast", "Audio Engineer", [ audio_engineer ])
    available_equipment = FakeItem.new(4, "Cable Tester", "", "", [ lighting_designer ])

    result = render_inline(
      Usr::ProfileConfig::SkillEquipmentFormComponent.new(
        profile: profile,
        skills: [ selected_skill, available_skill ],
        equipment: [ selected_equipment, available_equipment ],
        profile_occupations: [ stage_manager, lighting_designer, audio_engineer ],
        profile_skills: [ selected_skill ],
        profile_equipment: [ selected_equipment ],
        show_navigation: false
      )
    )

    skill_option_texts = result.css("[data-taxonomy-multiselect-target='option'][data-taxonomy-kind='skill']").map { |node| node["data-taxonomy-name"] }
    equipment_option_texts = result.css("[data-taxonomy-multiselect-target='option'][data-taxonomy-kind='equipment']").map { |node| node["data-taxonomy-name"] }
    selected_texts = result.css(".selected-occupation-pill").map { |node| node.text.strip }
    skill_section_html = result.css("#skills_selection_section").to_html
    equipment_section_html = result.css("#equipment_selection_section").to_html

    assert_equal 1, result.css("#skill_equipment_selection_content").count
    assert_includes result.text, "Skills & Services"
    assert_includes result.text, "Equipment & Platforms"
    assert_includes result.text, "Selected skills"
    assert_includes result.text, "Selected equipment"
    assert_equal [ "Audio Mixing", "Lighting Design" ], skill_option_texts
    assert_equal [ "Cable Tester", "Stage Console" ], equipment_option_texts
    assert_selector "[data-controller='taxonomy-multiselect']", count: 2
    assert_selector "input[type='search'][role='combobox'][aria-autocomplete='list']", count: 2
    assert_selector "[data-taxonomy-multiselect-target='options'][role='listbox']", count: 2
    assert_selector "[data-taxonomy-multiselect-target='status'][role='status']", count: 2
    assert_selector "[data-taxonomy-multiselect-target='option'][role='option']", count: 4
    assert_includes skill_section_html, "Audio Engineer"
    assert_includes skill_section_html, "Lighting Designer"
    refute_includes skill_section_html, "Stage Manager"
    assert_includes equipment_section_html, "Audio Engineer"
    assert_includes equipment_section_html, "Lighting Designer"
    refute_includes equipment_section_html, "Stage Manager"
    assert_equal [ "Lighting Design", "Stage Console" ], selected_texts
  end

  test "renders the empty state inside the component" do
    profile = FakeProfile.new(42)

    result = render_inline(
      Usr::ProfileConfig::SkillEquipmentFormComponent.new(
        profile: profile,
        skills: [],
        equipment: [],
        profile_occupations: [],
        profile_skills: [],
        profile_equipment: [],
        show_navigation: false
      )
    )

    assert_includes result.to_html, "You have not selected any occupations yet."
  end
end
