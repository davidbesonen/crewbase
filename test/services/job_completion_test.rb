require "test_helper"

class JobCompletionTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    owner = User.create!(
      first_name: "Completion",
      last_name: "Owner",
      email: "completion-owner@example.com",
      password: "password123"
    )
    industry = Industry.create!(name: "Completion Industry")
    @company = Company.create!(name: "Completion Co", contact_email: "completion@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: owner, role: "owner")
    @job = @company.jobs.create!(
      title: "Festival",
      employment_type: :contract,
      workplace_type: :on_site,
      posting_type: :multi_position,
      starts_at: Time.zone.local(2026, 7, 8, 8),
      ends_at: Time.zone.local(2026, 7, 10, 20),
      description: "Festival crew"
    )
    @profile = owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @position = @job.crew_positions.create!(title: "A1", headcount: 1)
    @position.crew_assignments.create!(profile: @profile)
  end

  test "creates a verified credit for assigned crew when work is completed" do
    assert_difference [ -> { @profile.credits.count }, -> { @profile.user.notifications.count } ], 1 do
      JobCompletion.new(job: @job).call
    end

    credit = @profile.credits.last
    assert_equal @job, credit.job
    assert_equal @company, credit.company
    assert_equal "A1", credit.role
    assert_equal "Festival", credit.project_name
    assert_equal Date.new(2026, 7, 8), credit.starts_on
    assert_equal Date.new(2026, 7, 10), credit.ends_on
    assert credit.verified?

    notification = @profile.user.notifications.last
    assert_equal "crewbase_credit_earned", notification.kind
    assert_equal credit, notification.notifiable
    assert_match "added to your profile", notification.message
  end

  test "does not expose the company project through the worker credit" do
    internal_project = @company.projects.create!(name: "Confidential Client Launch")
    @job.update!(project: internal_project, title: "Festival A1")

    JobCompletion.new(job: @job).call

    credit = @profile.credits.last
    assert_nil credit.project
    assert_equal "Festival A1", credit.project_name
  end

  test "is idempotent for the same profile and job" do
    JobCompletion.new(job: @job).call

    assert_no_difference [ -> { @profile.credits.count }, -> { @profile.user.notifications.count } ] do
      JobCompletion.new(job: @job).call
    end
  end

  test "does not award credits before the job has ended" do
    @job.update!(ends_at: 1.week.from_now)

    assert_raises(ActiveRecord::RecordInvalid) { JobCompletion.new(job: @job).call }
    assert_empty @profile.credits
  end

  test "awards accepted applicants even when a job does not use crew positions" do
    worker = User.create!(first_name: "Accepted", last_name: "Worker", email: "accepted-completion@example.com", password: "password123")
    profile = worker.profiles.create!(profile_type: "user", completed_at: Time.current)
    single_role_job = @company.jobs.create!(
      title: "One-night camera call",
      employment_type: :contract,
      workplace_type: :on_site,
      posting_type: :single_role,
      starts_at: 3.days.ago,
      ends_at: 2.days.ago,
      description: "One-night crew call"
    )
    single_role_job.job_applications.create!(profile:, status: :accepted, submitted_at: 1.week.ago, decision_at: 4.days.ago)

    JobCompletion.new(job: single_role_job).call

    assert_equal single_role_job, profile.credits.last.job
    assert profile.credits.last.verified?
  end
end
