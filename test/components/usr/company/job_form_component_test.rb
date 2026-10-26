require "test_helper"

class Usr::Company::JobFormComponentTest < ViewComponent::TestCase
  Entitlement = Struct.new(:available) do
    def allowed?(_feature) = available
  end

  test "keeps a searchable occupation picker and uses personal requirement text fields" do
    job = jobs(:one)
    job.job_requirements.create!(requirement: occupations(:one), importance: :required)
    job.job_requirements.create!(requirement: skills(:one), importance: :required)
    render_inline Usr::Company::JobFormComponent.new(
      company: companies(:one), job: job, occupations: [ occupations(:one), occupations(:two) ], entitlement: Entitlement.new(true)
    )
    assert_selector "[data-controller='taxonomy-multiselect']", count: 1
    assert_selector "select[name='job[required_occupation_ids][]'][multiple]", visible: false
    assert_selector "[data-taxonomy-multiselect-target='chip'][data-taxonomy-value='#{occupations(:one).id}']"
    assert_selector "textarea[name='job[required_skills_text]']", text: "Pro Tools"
    assert_selector "textarea[name='job[preferred_skills_text]']"
    assert_selector "textarea[name='job[required_equipment_text]']"
    assert_selector "textarea[name='job[preferred_equipment_text]']"
    assert_no_selector "select[name='job[required_skill_ids][]']", visible: false
  end
end
