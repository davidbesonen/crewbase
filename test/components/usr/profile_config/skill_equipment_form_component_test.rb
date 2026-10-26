require "test_helper"

class Usr::ProfileConfig::SkillEquipmentFormComponentTest < ViewComponent::TestCase
  test "collects personal skills and equipment without shared pickers" do
    profile = Profile.new(id: 42, skills_text: "RF coordination\nPro Tools", equipment_text: "My uncommon console")
    render_inline Usr::ProfileConfig::SkillEquipmentFormComponent.new(profile: profile, show_navigation: false)

    assert_selector "textarea[name='profile[skills_text]']", text: /RF coordination/
    assert_selector "textarea[name='profile[equipment_text]']", text: /My uncommon console/
    assert_selector "textarea[name='profile[work_examples]']"
    assert_no_selector "[data-controller='taxonomy-multiselect']"
    assert_text "One entry per line"
  end

  test "previous selections are prefilled and can be cleared" do
    profile = Profile.new(id: 42, skills: [ skills(:one) ], equipment: [ equipment(:one) ])
    render_inline Usr::ProfileConfig::SkillEquipmentFormComponent.new(profile: profile, show_navigation: false)
    assert_selector "textarea[name='profile[skills_text]']", text: "Pro Tools"
    assert_selector "textarea[name='profile[equipment_text]']", text: "Wireless Microphone"
  end
end
