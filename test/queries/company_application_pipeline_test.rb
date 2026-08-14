require "test_helper"

class CompanyApplicationPipelineTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    owner = User.create!(
      first_name: "Pipeline",
      last_name: "Owner",
      email: "pipeline-query-owner@example.com",
      password: "password123"
    )
    profile = owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    owner.visits.create!

    industry = Industry.create!(name: "Pipeline Query")
    @company = Company.create!(
      name: "Pipeline Company",
      contact_email: "pipeline-query@example.com",
      industries: [ industry ]
    )
    CompanyAssignment.create!(company: @company, user: owner, role: "owner")
    @first_job = Job.create!(
      company: @company,
      title: "Audio Engineer",
      workplace_type: :on_site,
      employment_type: :full_time,
      status: :published,
      description: "Audio role"
    )
    @second_job = Job.create!(
      company: @company,
      title: "Lighting Designer",
      workplace_type: :on_site,
      employment_type: :full_time,
      status: :published,
      description: "Lighting role"
    )
    @submitted = create_application(@first_job, "Ada", "Applicant", :submitted, 2.days.ago)
    @shortlisted = create_application(@second_job, "Sam", "Shortlist", :shortlisted, 1.day.ago)

    other_company = Company.create!(
      name: "Other Company",
      contact_email: "other-pipeline@example.com",
      industries: [ industry ]
    )
    other_job = Job.create!(
      company: other_company,
      title: "Unrelated Role",
      workplace_type: :remote,
      employment_type: :contract,
      status: :published,
      description: "Unrelated"
    )
    create_application(other_job, profile.user.first_name, "Elsewhere", :submitted, Time.current)
  end

  test "returns only the company's applications with stage counts" do
    pipeline = CompanyApplicationPipeline.new(company: @company)

    assert_equal [ @shortlisted, @submitted ], pipeline.results
    assert_equal 2, pipeline.total_count
    assert_equal 1, pipeline.stage_counts.fetch("submitted")
    assert_equal 1, pipeline.stage_counts.fetch("shortlisted")
    assert_equal 0, pipeline.stage_counts.fetch("rejected")
  end

  test "filters by stage job and applicant name" do
    pipeline = CompanyApplicationPipeline.new(
      company: @company,
      filters: { status: "shortlisted", job_id: @second_job.id, query: "sam" }
    )

    assert_equal [ @shortlisted ], pipeline.results
    assert_equal "shortlisted", pipeline.status
    assert_equal @second_job.id.to_s, pipeline.job_id
    assert_equal "sam", pipeline.query
    assert_equal 1, pipeline.total_count
    assert_equal 0, pipeline.stage_counts.fetch("submitted")
    assert_equal 1, pipeline.stage_counts.fetch("shortlisted")
  end

  test "filters results and summary counts to jobs in a project" do
    project = @company.projects.create!(name: "Festival Weekend")
    @first_job.update!(project:)

    pipeline = CompanyApplicationPipeline.new(
      company: @company,
      filters: { project_id: project.id }
    )

    assert_equal [ @submitted ], pipeline.results
    assert_equal project.id.to_s, pipeline.project_id
    assert_equal [ @first_job ], pipeline.jobs
    assert_equal 1, pipeline.total_count
    assert_equal 1, pipeline.stage_counts.fetch("submitted")
    assert_equal 0, pipeline.stage_counts.fetch("shortlisted")
  end

  test "ignores invalid filters" do
    pipeline = CompanyApplicationPipeline.new(
      company: @company,
      filters: { status: "withdrawn", job_id: "not-an-id", project_id: "not-an-id" }
    )

    assert_equal [ @shortlisted, @submitted ], pipeline.results
    assert_nil pipeline.status
    assert_nil pipeline.job_id
    assert_nil pipeline.project_id
  end

  private

  def create_application(job, first_name, last_name, status, created_at)
    user = User.create!(
      first_name: first_name,
      last_name: last_name,
      email: "#{first_name.downcase}-#{last_name.downcase}-#{job.id}@example.com",
      password: "password123"
    )
    profile = user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    JobApplication.create!(job: job, profile: profile, status: status, created_at: created_at)
  end
end
