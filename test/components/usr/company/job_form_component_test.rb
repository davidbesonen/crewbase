# frozen_string_literal: true

require "test_helper"

class Usr::Company::JobFormComponentTest < ViewComponent::TestCase
  Entitlement = Struct.new(:available) do
    def allowed?(_feature) = available
  end

  test "renders searchable tokenized comboboxes for every taxonomy requirement" do
    job = jobs(:one)
    selected_skill = skills(:one)
    job.job_requirements.create!(
      requirement: selected_skill,
      importance: :required,
      source: :employer,
      confirmed_at: Time.current
    )

    result = render_inline(
      Usr::Company::JobFormComponent.new(
        company: companies(:one),
        job: job,
        occupations: [ occupations(:two), occupations(:one) ],
        skills: [ skills(:one), skills(:two) ],
        equipment: [ equipment(:one), equipment(:two) ],
        entitlement: Entitlement.new(true)
      )
    )

    assert_selector "[data-controller='taxonomy-multiselect']", count: 5
    assert_selector "input[type='search'][role='combobox'][aria-autocomplete='list']", count: 5
    assert_selector "[data-taxonomy-multiselect-target='options'][role='listbox']", count: 5
    assert_selector "select[data-taxonomy-multiselect-target='select']", visible: false, count: 5

    %w[
      required_occupation_ids
      required_skill_ids
      preferred_skill_ids
      required_equipment_ids
      preferred_equipment_ids
    ].each do |attribute|
      assert_selector "select[name='job[#{attribute}][]'][multiple]", visible: false
    end

    required_skills = result.css(
      "#job_required_skill_ids_combobox [data-taxonomy-multiselect-target='option']"
    ).map { |node| node["data-taxonomy-name"] }
    assert_equal [ "Acoustic Guitar", "Pro Tools" ], required_skills

    assert_selector(
      "#job_required_skill_ids_combobox " \
      "[data-taxonomy-multiselect-target='chip'][data-taxonomy-value='#{selected_skill.id}']",
      text: "Pro Tools"
    )
    assert_selector(
      "#job_required_skill_ids_combobox " \
      ".taxonomy-multiselect-control + .taxonomy-multiselect-chips"
    )
    assert_selector(
      "#job_required_skill_ids_combobox " \
      "[data-taxonomy-multiselect-target='option'][aria-selected='true'][data-taxonomy-value='#{selected_skill.id}']"
    )
  end

  test "uses semantic button roles for neutral constructive and destructive actions" do
    render_inline(
      Usr::Company::JobFormComponent.new(
        company: companies(:one),
        job: jobs(:one),
        entitlement: Entitlement.new(true)
      )
    )

    assert_selector "a.btn-quiet", text: "Back to Company"
    assert_selector "button.btn-outline-primary[data-action='question-fields#add']", text: "Add Question"
    assert_selector "button.btn-outline-primary[data-action='work-date-fields#add']", text: "Add Work Date"
    assert_selector "button.btn-outline-danger[data-action='work-date-fields#remove']", minimum: 1
  end
end
