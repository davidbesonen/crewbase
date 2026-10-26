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
    assert_selector "textarea[name='job[required_skills_text]']", text: "Pro Tools", visible: :all
    assert_selector "textarea[name='job[preferred_skills_text]']", visible: :all
    assert_selector "textarea[name='job[required_equipment_text]']", visible: :all
    assert_selector "textarea[name='job[preferred_equipment_text]']", visible: :all
    assert_no_selector "select[name='job[required_skill_ids][]']", visible: false
  end

  test "empty specific requirements are collapsed and explain their matching consequences" do
    render_inline Usr::Company::JobFormComponent.new(company: companies(:one), job: Job.new, entitlement: Entitlement.new(true))
    assert_selector "details[data-specific-requirements]:not([open])"
    assert_no_selector "textarea[name='job[required_skills_text]']"
    assert_selector "[data-specific-requirements]", text: "Required entries filter job recommendations", visible: :all
    assert_selector "[data-specific-requirements]", text: "Preferred entries improve ranking", visible: :all
    assert_selector "[data-specific-requirements]", text: "Other alternate names and spellings are not matched automatically", visible: :all
    assert_selector "[data-specific-requirements]", text: "MA3 and grandMA3 are recognized as the same console family; MA2 is separate", visible: :all
  end

  test "existing or invalid specific requirements are expanded" do
    job = Job.new(preferred_equipment_text: "Vectorworks")
    render_inline Usr::Company::JobFormComponent.new(company: companies(:one), job:, entitlement: Entitlement.new(true))
    assert_selector "details[data-specific-requirements][open] textarea", text: "Vectorworks"

    job.preferred_equipment_text = ""
    job.errors.add(:required_skills_text, "has too many entries")
    render_inline Usr::Company::JobFormComponent.new(company: companies(:one), job:, entitlement: Entitlement.new(true))
    assert_selector "details[data-specific-requirements][open]"
  end
end
