require "test_helper"

class AcceptJobApplicationTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = create_user("accept-service-owner")
    applicant = create_user("accept-service-applicant")
    industry = Industry.create!(name: "Acceptance Service")
    @company = Company.create!(
      name: "Acceptance Service Co",
      contact_email: "acceptance-service@example.com",
      industries: [ industry ]
    )
    @company.company_assignments.create!(user: @owner, role: "owner")
    @job = @company.jobs.create!(
      title: "Festival Production",
      posting_type: :multi_position,
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      description: "Staff the festival.",
      crew_positions_attributes: [ { title: "Lighting Technician", headcount: 1 } ]
    )
    @application = @job.job_applications.create!(profile: applicant.user_profile)
    @position = @job.crew_positions.sole
  end

  test "accepts a gig application and assigns the applicant to the selected position atomically" do
    result = AcceptJobApplication.new(
      application: @application,
      reviewer: @owner,
      crew_position: @position
    ).call

    assert result.success?
    assert @application.reload.accepted?
    assert_equal @owner.id, @application.reviewed_by
    assert_not_nil @application.decision_at
    assert_equal @application.profile, @position.crew_assignments.sole.profile
  end

  test "rejects a gig acceptance without a position and leaves the application unchanged" do
    result = AcceptJobApplication.new(application: @application, reviewer: @owner).call

    assert_not result.success?
    assert_equal "Select a position for this gig.", result.error
    assert @application.reload.submitted?
    assert_empty @job.crew_assignments
  end

  test "rejects a position from another gig" do
    other_job = @company.jobs.create!(
      title: "Other Gig",
      posting_type: :multi_position,
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      description: "A different gig.",
      crew_positions_attributes: [ { title: "Camera Operator", headcount: 1 } ]
    )
    other_position = other_job.crew_positions.sole

    result = AcceptJobApplication.new(
      application: @application,
      reviewer: @owner,
      crew_position: other_position
    ).call

    assert_not result.success?
    assert_equal "That position does not belong to this gig.", result.error
    assert @application.reload.submitted?
    assert_empty other_position.crew_assignments
  end

  test "rejects a full position and leaves the application unchanged" do
    staffed_profile = create_user("accept-service-staffed").user_profile
    @position.crew_assignments.create!(profile: staffed_profile)

    result = AcceptJobApplication.new(
      application: @application,
      reviewer: @owner,
      crew_position: @position
    ).call

    assert_not result.success?
    assert_equal "That position is already fully staffed.", result.error
    assert @application.reload.submitted?
    assert_equal staffed_profile, @position.crew_assignments.sole.profile
  end

  test "accepts a single-role application without creating a crew assignment" do
    single_job = @company.jobs.create!(
      title: "Audio Engineer",
      posting_type: :single_role,
      workplace_type: :on_site,
      employment_type: :full_time,
      status: :published,
      description: "A single-role opening."
    )
    application = single_job.job_applications.create!(profile: @application.profile)

    result = AcceptJobApplication.new(application:, reviewer: @owner).call

    assert result.success?
    assert application.reload.accepted?
    assert_empty single_job.crew_assignments
  end

  private

  def create_user(label)
    user = User.create!(
      first_name: label.titleize,
      last_name: "User",
      email: "#{label}@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end
end
