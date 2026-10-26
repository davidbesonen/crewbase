require "test_helper"

class Usr::JobApplication::FormComponentTest < ViewComponent::TestCase
  test "failed applications explain errors and file limits with an accessible editor label" do
    job = Job.new(id: 42, title: "Camera operator", questions: [])
    application = JobApplication.new(job:)
    application.errors.add(:base, "This job is no longer accepting applications.")
    render_inline Usr::JobApplication::FormComponent.new(job:, job_application: application)
    assert_selector "[role='alert']", text: "This job is no longer accepting applications."
    assert_text "35 MB"
    assert_selector "label[for='job_application_additional_information']", text: "Additional information"
    assert_text "Optional"
  end
end
