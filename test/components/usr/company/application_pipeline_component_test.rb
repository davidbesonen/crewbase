require "test_helper"

class Usr::Company::ApplicationPipelineComponentTest < ViewComponent::TestCase
  self.fixture_table_names = []

  test "renders stage totals, applications, and valid transition actions" do
    company = Company.new(id: 41, name: "Pipeline Preview")
    job = Job.new(id: 52, company: company, title: "Camera Operator")
    user = User.new(first_name: "Casey", last_name: "Candidate")
    profile = Profile.new(id: 63, user: user)
    application = JobApplication.new(
      id: 74,
      job: job,
      profile: profile,
      status: :submitted,
      submitted_at: Time.zone.local(2026, 7, 20)
    )

    render_inline Usr::Company::ApplicationPipelineComponent.new(
      company: company,
      applications: [ application ],
      jobs: [ job ],
      filters: {},
      stage_counts: JobApplication.review_pipeline_statuses.index_with { 0 }.merge("submitted" => 1),
      total_count: 1
    )

    assert_selector "[data-pipeline-stage='submitted']", text: /1/
    assert_selector "[data-pipeline-application='74']", text: /Casey Candidate/
    profile_path = Rails.application.routes.url_helpers.usr_profile_path(profile)
    assert_selector "[data-pipeline-application='74'] h2 a[href='#{profile_path}'].text-decoration-none", text: "Casey Candidate"
    assert_selector "a[href='#{Rails.application.routes.url_helpers.usr_job_application_path(application)}']", text: "View Application"
    assert_selector "a[data-turbo-method='patch']", text: "Mark In Review"
    assert_selector "a[data-turbo-method='patch']", text: "Shortlist"
    assert_selector "a[data-turbo-method='patch']", text: "Accept"
    assert_selector "a[data-turbo-method='patch']", text: "Reject"
  end

  test "renders every status action in a consistent order and disables the current status" do
    company = Company.new(id: 41, name: "Pipeline Preview")
    job = Job.new(id: 52, company:, title: "Camera Operator")
    profile = Profile.new(id: 63, user: User.new(first_name: "Casey", last_name: "Candidate"))
    application = JobApplication.new(id: 74, job:, profile:, status: :shortlisted, submitted_at: Time.zone.local(2026, 7, 20))

    render_inline Usr::Company::ApplicationPipelineComponent.new(
      company:,
      applications: [ application ],
      jobs: [ job ],
      filters: {},
      stage_counts: JobApplication.review_pipeline_statuses.index_with { 0 }.merge("shortlisted" => 1),
      total_count: 1
    )

    document = Nokogiri::HTML.fragment(rendered_content)
    actions = document.css("[data-pipeline-actions] .btn")
    assert_equal [ "Mark In Review", "Shortlist", "Accept", "Reject" ], actions.map { |action| action.text.strip }
    assert_equal "button", actions[1].name
    assert actions[1].key?("disabled")
    assert_equal "true", actions[1]["aria-disabled"]
    assert_includes actions[1]["class"].split, "btn-secondary"
    assert_not_includes actions[1]["class"].split, "btn-outline-primary"
    assert_equal 3, document.css("[data-pipeline-actions] a[data-turbo-method='patch']").count
  end

  test "uses restrained color to distinguish the pipeline header, stages, and application status" do
    company = Company.new(id: 41, name: "Pipeline Preview")
    job = Job.new(id: 52, company: company, title: "Camera Operator")
    profile = Profile.new(id: 63, user: User.new(first_name: "Casey", last_name: "Candidate"))
    application = JobApplication.new(id: 74, job:, profile:, status: :submitted, submitted_at: Time.zone.local(2026, 7, 20))

    render_inline Usr::Company::ApplicationPipelineComponent.new(
      company:,
      applications: [ application ],
      jobs: [ job ],
      filters: {},
      stage_counts: JobApplication.review_pipeline_statuses.index_with { 0 }.merge("submitted" => 1),
      total_count: 1
    )

    assert_selector ".app-hero.app-hero-navy"
    assert_selector "[data-pipeline-stage='submitted'].card-accent.card-accent-cyan"
    assert_selector "[data-pipeline-application='74'].card-accent.card-accent-navy"
    assert_selector "[data-pipeline-application='74'] .status-badge"
  end

  test "offers direct acceptance without a position selector for a multi-position gig application" do
    company = Company.new(id: 41, name: "Pipeline Preview")
    job = Job.new(id: 52, company:, title: "Festival Crew", posting_type: :multi_position)
    profile = Profile.new(id: 63, user: User.new(first_name: "Casey", last_name: "Candidate"))
    application = JobApplication.new(id: 74, job:, profile:, status: :submitted, submitted_at: Time.zone.local(2026, 7, 20))

    render_inline Usr::Company::ApplicationPipelineComponent.new(
      company:,
      applications: [ application ],
      jobs: [ job ],
      filters: {},
      stage_counts: JobApplication.review_pipeline_statuses.index_with { 0 }.merge("submitted" => 1),
      total_count: 1
    )

    assert_selector "a[data-turbo-method='patch'][href*='status=accepted']", text: "Accept"
    assert_no_selector "select[name='crew_position_id']"
    assert_no_selector "input[type='submit'][value='Accept for Position']"
  end

  test "gives rejected applications a subtle red background" do
    company = Company.new(id: 41, name: "Pipeline Preview")
    job = Job.new(id: 52, company:, title: "Camera Operator")
    profile = Profile.new(id: 63, user: User.new(first_name: "Casey", last_name: "Candidate"))
    application = JobApplication.new(id: 74, job:, profile:, status: :rejected, submitted_at: Time.zone.local(2026, 7, 20))

    render_inline Usr::Company::ApplicationPipelineComponent.new(
      company:,
      applications: [ application ],
      jobs: [ job ],
      filters: {},
      stage_counts: JobApplication.review_pipeline_statuses.index_with { 0 }.merge("rejected" => 1),
      total_count: 1
    )

    assert_selector "[data-pipeline-application='74'].bg-danger-subtle"
  end
end
