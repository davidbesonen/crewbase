require "test_helper"

class Usr::Company::ProjectFormComponentTest < ViewComponent::TestCase
  test "a new project only asks for a name before continuing to its first job" do
    render_inline Usr::Company::ProjectFormComponent.new(company: companies(:one), project: Project.new)
    assert_selector "input[name='project[name]']"
    assert_selector "details[data-project-options]:not([open])"
    assert_selector "button[name='next_step'][value='post_job']", text: "Create project & post a job"
    assert_selector "input[type='submit'][value='Create project only']"
  end

  test "existing project details remain visible and editable" do
    project = Project.new(description: "Summer shows", starts_on: Date.new(2030, 2, 10), status: :active)
    render_inline Usr::Company::ProjectFormComponent.new(company: companies(:one), project:)
    assert_selector "details[data-project-options][open] textarea", text: "Summer shows"
    assert_selector "input[type='date'][value='2030-02-10']"
    assert_selector "select[name='project[status]'] option[selected][value='active']"
  end
end
