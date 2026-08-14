require "test_helper"

class Usr::JobApplicationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = User.create!(
      first_name: "Owner",
      last_name: "User",
      email: "owner@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @owner_profile = @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!

    @applicant = User.create!(
      first_name: "Applicant",
      last_name: "User",
      email: "applicant@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @applicant_profile = @applicant.profiles.create!(profile_type: "user", completed_at: Time.current)
    @applicant.visits.create!

    @outsider = User.create!(
      first_name: "Outsider",
      last_name: "User",
      email: "outsider@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    @outsider.profiles.create!(profile_type: "user", completed_at: Time.current)
    @outsider.visits.create!

    industry = Industry.create!(name: "Application Status")
    @company = Company.create!(
      name: "Status Test Co",
      contact_email: "company@example.com",
      industries: [ industry ]
    )
    CompanyAssignment.create!(company: @company, user: @owner, role: "owner")

    @job = Job.create!(
      company: @company,
      title: "Audio Engineer",
      workplace_type: :on_site,
      employment_type: :full_time,
      status: :published,
      description: "Test job description"
    )
    @job_application = JobApplication.create!(
      job: @job,
      profile: @applicant_profile,
      status: :submitted
    )
  end

  test "company owner can update an application to each review status" do
    sign_in @owner, scope: :user

    JobApplication.review_statuses.each do |status|
      patch update_status_usr_job_application_path(@job_application), params: { status: status }

      assert_redirected_to usr_job_application_path(@job_application)
      assert_equal "Application status updated to #{status.humanize.titleize}.", flash[:notice]

      @job_application.reload
      assert_equal status, @job_application.status
      assert_not_nil @job_application.reviewed_at
      assert_equal @owner.id, @job_application.reviewed_by

      if JobApplication.decision_statuses.include?(status)
        assert_not_nil @job_application.decision_at
      else
        assert_nil @job_application.decision_at
      end

      @job_application.update_columns(
        status: JobApplication.statuses[:submitted],
        reviewed_at: nil,
        reviewed_by: nil,
        decision_at: nil
      )
    end
  end

  test "applicant index combines applications with pending and past invitations" do
    pending_job = create_invitable_job("Camera Operator")
    declined_job = create_invitable_job("Lighting Technician")
    pending_invitation = JobInvitationCreator.new(
      job: pending_job,
      profile: @applicant_profile,
      invited_by: @owner
    ).call
    declined_invitation = JobInvitationCreator.new(
      job: declined_job,
      profile: @applicant_profile,
      invited_by: @owner
    ).call
    declined_invitation.decline!
    sign_in @applicant, scope: :user

    get usr_job_applications_path

    assert_response :success
    assert_select ".app-hero.app-hero-sky", text: /Applications & Invitations/
    assert_select "[data-pending-invitations]" do
      assert_select "a[href='#{usr_job_path(pending_job)}']", text: pending_job.title
      assert_select "a[href='#{accept_usr_job_invitation_path(pending_invitation)}']", text: "Apply now"
      assert_select "a[href='#{decline_usr_job_invitation_path(pending_invitation)}']", text: "Decline"
      assert_select "form[action='#{usr_job_invitation_contextual_messages_path(pending_invitation)}']"
    end
    assert_select "[data-invitation-history]" do
      assert_select "*", text: /#{Regexp.escape(declined_job.title)}/
      assert_select ".status-badge", text: "Declined"
    end
    assert_select ".card-accent.card-accent-sky"
    assert_select ".status-badge.status-unknown", text: "Submitted"
  end

  test "submitting an application completes its pending invitation" do
    invitation = JobInvitationCreator.new(
      job: @job,
      profile: @applicant_profile,
      invited_by: @owner
    ).call
    @job_application.destroy!
    sign_in @applicant, scope: :user

    post usr_job_job_applications_path(@job), params: {
      job_application: { additional_information: "I would love to help." }
    }

    assert_redirected_to usr_job_path(@job)
    assert invitation.reload.accepted?
    assert_not_nil invitation.responded_at
  end

  test "company owner cannot update an application to a non-review status" do
    sign_in @owner, scope: :user

    patch update_status_usr_job_application_path(@job_application), params: { status: :withdrawn }

    assert_redirected_to usr_job_application_path(@job_application)
    assert_equal "Status is invalid for review.", flash[:alert]

    @job_application.reload
    assert_equal "submitted", @job_application.status
    assert_nil @job_application.reviewed_at
    assert_nil @job_application.decision_at
  end

  test "non-owner cannot update an application status" do
    sign_in @outsider, scope: :user

    patch update_status_usr_job_application_path(@job_application), params: { status: :accepted }

    assert_response :not_found

    @job_application.reload
    assert_equal "submitted", @job_application.status
  end

  test "owner accepts a multi-position gig applicant into a selected position" do
    @job.update!(posting_type: :multi_position)
    position = @job.crew_positions.create!(title: "Audio Lead", headcount: 1)
    sign_in @owner, scope: :user

    patch update_status_usr_job_application_path(@job_application), params: {
      status: :accepted,
      crew_position_id: position.id
    }

    assert_redirected_to usr_job_application_path(@job_application)
    assert_equal "Application accepted for Audio Lead.", flash[:notice]
    assert @job_application.reload.accepted?
    assert_equal @applicant_profile, position.crew_assignments.sole.profile
  end

  test "owner accepts a multi-position gig applicant without assigning a position" do
    @job.update!(posting_type: :multi_position)
    @job.crew_positions.create!(title: "Audio Lead", headcount: 1)
    sign_in @owner, scope: :user

    patch update_status_usr_job_application_path(@job_application), params: { status: :accepted }

    assert_redirected_to usr_job_application_path(@job_application)
    assert_equal "Application status updated to Accepted.", flash[:notice]
    assert @job_application.reload.accepted?
    assert_empty @job.crew_assignments
  end

  test "individual application review offers a position selector for gig acceptance" do
    @job.update!(posting_type: :multi_position)
    position = @job.crew_positions.create!(title: "Audio Lead", headcount: 1)
    sign_in @owner, scope: :user

    get usr_job_application_path(@job_application)

    assert_response :success
    assert_select "form[action='#{update_status_usr_job_application_path(@job_application)}']" do
      assert_select "input[name='status'][value='accepted']"
      assert_select "select[name='crew_position_id'] option[value='#{position.id}']", text: "Audio Lead"
      assert_select "input[type='submit'][value='Accept for Position']"
    end
    assert_select "a", text: "Accepted", count: 0
  end

  private

  def create_invitable_job(title)
    Job.create!(
      company: @company,
      title:,
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      is_active: true,
      description: "Test job description"
    )
  end
end
