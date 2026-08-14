require "test_helper"

class Usr::Company::ApplicationsTabComponentTest < ViewComponent::TestCase
  self.fixture_table_names = []

  test "links owners to the full application pipeline" do
    company = Company.new(id: 91, name: "Pipeline Link Co")

    render_inline Usr::Company::ApplicationsTabComponent.new(
      company: company,
      job_applications: [],
      pipeline_available: true
    )

    assert_link "Open Pipeline", href: "/usr/companies/91/applications"
    assert_link "0 applications across this company's jobs.", href: "/usr/companies/91/applications"
  end

  test "renders application stages with semantic status color" do
    company = Company.new(id: 91, name: "Pipeline Link Co")
    job = Job.new(id: 92, title: "A1", company:)
    profile = Profile.new(id: 93, user: User.new(first_name: "Alex", last_name: "Applicant"))
    application = JobApplication.new(id: 94, job:, profile:, status: :shortlisted, submitted_at: Time.zone.local(2026, 7, 20))

    render_inline Usr::Company::ApplicationsTabComponent.new(company:, job_applications: [ application ], pipeline_available: true)

    assert_selector ".status-badge.status-warning", text: "Shortlisted"
  end
end
