require "test_helper"

class Usr::ExperienceCategoryFieldsComponentTest < ViewComponent::TestCase
  test "occupation core work is explained instead of offered as another selection" do
    actor = Occupation.new(id: 99, name: "Actor")
    render_inline Usr::ExperienceCategoryFieldsComponent.new(record: Profile.new, scope: :profile,
      occupations: [ actor ], selected_occupation_ids: [ actor.id ])
    assert_selector "[data-category-core-summary]", text: "Included through occupations"
    assert_selector "[data-category-row][hidden] input[value='performance'][disabled]", visible: :all
    assert_selector "[data-category-row][hidden] input[value='acting_voice'][disabled]", visible: :all
    assert_selector "[data-category-primary] input[value='rehearsal_management']:not([disabled])"
  end

  test "umbrella equipment choices are retired while saved selections remain removable" do
    render_inline Usr::ExperienceCategoryFieldsComponent.new(record: Profile.new, scope: :profile)
    assert_no_selector "input[value='audio_systems']", visible: :all
    assert_selector "input[value='mixing_consoles']", visible: :all
    assert_selector "input[value='pa_systems']", visible: :all

    render_inline Usr::ExperienceCategoryFieldsComponent.new(record: Profile.new(equipment_family_keys: [ "audio_systems" ]), scope: :profile)
    assert_selector "input[value='audio_systems'][checked]:not([disabled])"
  end

  test "saved core choices remain removable and job requirements use the same core guidance" do
    actor = Occupation.new(id: 99, name: "Actor")
    render_inline Usr::ExperienceCategoryFieldsComponent.new(record: Profile.new(capability_keys: [ "performance" ]), scope: :profile,
      occupations: [ actor ], selected_occupation_ids: [ actor.id ])
    assert_selector "input[value='performance'][checked]:not([disabled])"
    render_inline Usr::ExperienceCategoryFieldsComponent.new(record: Job.new, scope: :job,
      occupations: [ actor ], selected_occupation_ids: [ actor.id ])
    assert_selector "input[value='performance'][disabled]", count: 2, visible: :all
  end

  test "prioritizes occupation relevant and selected categories while keeping other choices" do
    occupation = Occupation.new(id: 99, name: "Camera Operator")
    profile = Profile.new(capability_keys: [ "audio" ])
    render_inline Usr::ExperienceCategoryFieldsComponent.new(record: profile, scope: :profile,
      occupations: [ occupation ], selected_occupation_ids: [ 99 ])
    assert_selector "[data-category-row][hidden] input[value='camera'][disabled]", visible: :all
    assert_selector "[data-category-primary] input[value='audio'][checked]"
    assert_selector "[data-category-other] input[value='lighting']", visible: :all
    assert_no_selector "[data-category-primary] input[value='lighting']"
    assert_selector "[data-category-primary] .form-check:first-child input[value='cinematic_lighting']"
    assert_selector "input[type='search'][id='profile_capability_keys_search']"
    assert_selector "input[type='checkbox']", count: ExperienceCategories.selectable("Skill").size + ExperienceCategories.selectable("Equipment").size, visible: :all
  end

  test "offers a bounded category list and preserves independent selections" do
    profile = Profile.new(capability_keys: [ "audio" ], equipment_family_keys: [ "audio_systems" ])
    render_inline Usr::ExperienceCategoryFieldsComponent.new(record: profile, scope: :profile)
    assert_selector "input[type='checkbox']", count: ExperienceCategories.selectable("Skill").size + ExperienceCategories.selectable("Equipment").size + 1, visible: :all
    assert_selector "input[name='profile[capability_keys][]'][value='audio'][checked]", visible: :all
    assert_selector "input[name='profile[equipment_family_keys][]'][value='audio_systems'][checked]", visible: :all
    assert_selector "input[type='hidden'][name='profile[capability_keys][]'][value='']", visible: :all
    assert_text "Audio production"
    assert_selector "label", text: "Mixing consoles, microphones, speakers and recording systems", visible: :all
    assert_no_text "Yamaha CL5"
  end

  test "job required and preferred categories are separate inputs" do
    job = Job.new(required_capability_keys: [ "audio" ], preferred_capability_keys: [ "planning" ])
    render_inline Usr::ExperienceCategoryFieldsComponent.new(record: job, scope: :job)
    assert_selector "input[name='job[required_capability_keys][]'][value='audio'][checked]", visible: :all
    assert_selector "input[name='job[preferred_capability_keys][]'][value='planning'][checked]", visible: :all
    assert_no_selector "input[name='job[required_capability_keys][]'][value='planning'][checked]", visible: :all
  end
end
