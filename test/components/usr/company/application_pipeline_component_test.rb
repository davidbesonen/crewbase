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
    assert_selector "a[href='/usr/job_offers/new?job_application_id=74']:not([data-turbo-method])", text: "Offer job"
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
    assert_equal [ "Mark In Review", "Shortlist", "Offer job", "Reject" ], actions.map { |action| action.text.strip }
    assert_equal "button", actions[1].name
    assert actions[1].key?("disabled")
    assert_equal "true", actions[1]["aria-disabled"]
    assert_includes actions[1]["class"].split, "btn-secondary"
    assert_not_includes actions[1]["class"].split, "btn-outline-primary"
    assert_equal 2, document.css("[data-pipeline-actions] a[data-turbo-method='patch']").count
  end

  test "uses a flat stage navigation and a single divided applicant list" do
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

    assert_selector "nav[aria-label='Application stages']"
    assert_selector "[data-pipeline-stage='submitted'].pipeline-stage"
    assert_selector ".pipeline-applicants > article[data-pipeline-application='74']"
    assert_no_selector ".card .card"
    assert_selector "[data-pipeline-application='74'] .status-badge"
  end

  test "makes the selected job and active stage clear" do
    company = Company.new(id: 41, name: "Pipeline Preview")
    job = Job.new(id: 52, company:, title: "Camera Operator")

    render_inline Usr::Company::ApplicationPipelineComponent.new(
      company:,
      applications: [],
      jobs: [ job ],
      filters: { job_id: "52", status: "shortlisted" },
      stage_counts: JobApplication.review_pipeline_statuses.index_with { 0 },
      total_count: 0
    )

    assert_selector "[data-pipeline-job-context]", text: /Camera Operator/
    assert_selector "[data-pipeline-job-context] a[href='/usr/jobs/52']", text: "Camera Operator"
    assert_selector "[data-pipeline-stage='shortlisted'][aria-current='page']", count: 1
    assert_selector "[data-pipeline-stage][aria-current='page']", count: 1
    assert_selector ".pipeline-results-summary", text: "Showing 0 applications"
    assert_selector "select[name='job_id'] option[selected][value='52']"
    assert_selector "a[href='/usr/jobs/52']", text: "Back to Job"
    assert_selector "a.pipeline-stage[href*='job_id=52']", text: /All stages/
    assert_no_selector "a.pipeline-stage[href*='status=shortlisted']", text: /All stages/
  end

  test "explains recommendations within the applicant row" do
    company = Company.new(id: 41, name: "Pipeline Preview")
    job = Job.new(id: 52, company:, title: "Camera Operator")
    profile = Profile.new(id: 63, user: User.new(first_name: "Casey", last_name: "Candidate"))
    application = JobApplication.new(id: 74, job:, profile:, status: :submitted, submitted_at: Time.zone.local(2026, 7, 20))
    recommendation = Struct.new(:match_reason, :availability_label).new("Matches Camera Operator", "Available for all dates")

    render_inline Usr::Company::ApplicationPipelineComponent.new(
      company:,
      applications: [ application ],
      recommendations: { application.id => recommendation },
      jobs: [ job ],
      filters: {},
      stage_counts: { "submitted" => 1 },
      total_count: 1
    )

    assert_selector ".pipeline-applicant .recommended-applicant-badge.text-bg-success", text: "Recommended Applicant"
    assert_selector ".pipeline-applicant [data-recommendation-reason]", text: "Matches Camera Operator • Available for all dates"
    assert_selector ".pipeline-applicant .bi-stars", count: 1
    assert_no_selector "[data-recommendation-reason] .bi-stars"
  end

  test "opens offer terms for a multi-position gig application" do
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

    assert_selector "a[href='/usr/job_offers/new?job_application_id=74']:not([data-turbo-method])", text: "Offer job"
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
  test "pending offers show their state and link instead of duplicate hiring actions" do
    application = preview_application(status: :shortlisted)
    application.job_offers.build(id: 85, status: :pending, created_at: Time.current)
    render_application(application)
    assert_selector ".pipeline-applicant-status", text: "Offer pending"
    assert_selector "[data-pipeline-actions] a[href='/usr/job_offers/85']", text: "View offer"
    assert_no_selector "[data-pipeline-actions] a[data-turbo-method='patch']"
    assert_no_selector "[data-pipeline-actions] a", text: "Offer job"
  end

  test "confirmed bookings have no review transitions" do
    application = preview_application(status: :accepted)
    application.job_offers.build(id: 85, status: :accepted, created_at: Time.current)
    render_application(application)
    assert_selector ".pipeline-applicant-status", text: "Booking confirmed"
    assert_selector "[data-pipeline-actions] a[href='/usr/job_offers/85']", text: "View booking"
    assert_no_selector "[data-pipeline-actions] a[data-turbo-method='patch']"
    assert_no_selector "[data-pipeline-actions] button"
  end

  private

  def preview_application(status:)
    company = Company.new(id: 41, name: "Pipeline Preview")
    job = Job.new(id: 52, company:, title: "Camera Operator")
    profile = Profile.new(id: 63, user: User.new(first_name: "Casey", last_name: "Candidate"))
    JobApplication.new(id: 74, job:, profile:, status:, submitted_at: Time.zone.local(2026, 7, 20))
  end

  def render_application(application)
    render_inline Usr::Company::ApplicationPipelineComponent.new(
      company: application.job.company, applications: [ application ], jobs: [ application.job ],
      filters: {}, stage_counts: {}, total_count: 1
    )
  end
end
