require "test_helper"

class Usr::Company::JobFormComponentTest < ViewComponent::TestCase
  Entitlement = Struct.new(:available) do
    def allowed?(_feature) = available
  end

  test "shows the essentials and tucks empty optional sections away" do
    render_inline Usr::Company::JobFormComponent.new(company: companies(:one), job: Job.new(posting_type: :single_role, schedule_has_times: false), entitlement: Entitlement.new(true))

    assert_selector "input[name='job[title]']"
    assert_selector "label[for='job_title']", text: "Job title"
    assert_selector "input[name='job[starts_at]']"
    assert_selector "input[name='job[locations_attributes][0][city]']"
    assert_selector "input[name='job[pay_min]']"
    %w[additional-experience screening-questions schedule-options street-address posting-options].each do |section|
      assert_selector "details[data-#{section}]:not([open])"
    end
    assert_selector "button[name='publication_action'][value='publish']", text: "Publish job"
    assert_selector "button[name='publication_action'][value='draft']", text: "Save draft"
    assert_no_selector "select[name='job[status]']", visible: :all
  end

  test "multi-position gigs use a gig title and separate role title" do
    render_inline Usr::Company::JobFormComponent.new(company: companies(:one), job: Job.new(posting_type: :multi_position), entitlement: Entitlement.new(true))
    assert_selector "label[for='job_title']", text: "Gig title"
    assert_selector "label[for='job_crew_positions_attributes_0_title']", text: "Role title"
  end

  test "saved optional values and validation errors stay visible" do
    job = Job.new(required_capability_keys: [ "audio" ], questions: [ "Which consoles do you know?" ],
      application_deadline: 2.weeks.from_now, employment_type: :full_time)
    job.locations.build(address_line_1: "1 Stage Road")
    render_inline Usr::Company::JobFormComponent.new(company: companies(:one), job:, entitlement: Entitlement.new(true))
    %w[additional-experience screening-questions schedule-options street-address posting-options].each do |section|
      assert_selector "details[data-#{section}][open]"
    end

    job = Job.new
    job.errors.add(:questions, "needs attention")
    render_inline Usr::Company::JobFormComponent.new(company: companies(:one), job:, entitlement: Entitlement.new(true))
    assert_selector "details[data-screening-questions][open]"
  end

  test "editing retains lifecycle controls and labels saving accurately" do
    render_inline Usr::Company::JobFormComponent.new(company: companies(:one), job: jobs(:one), entitlement: Entitlement.new(true))
    assert_selector "details[data-posting-options][open] select[name='job[status]']"
    assert_selector "input[type='submit'][value='Save changes']"
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
