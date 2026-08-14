require "test_helper"

class JobInvitationCreatorTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = create_user("owner-invite-service@example.com")
    @recipient = create_user("recipient-invite-service@example.com")
    @profile = @recipient.profiles.create!(profile_type: "user")
    industry = Industry.create!(name: "Invitation Service")
    company = Company.create!(name: "Invitation Service Co", contact_email: "invite-service@example.com", industries: [ industry ])
    CompanyAssignment.create!(company:, user: @owner, role: "owner")
    @job = Job.create!(
      company:,
      title: "Lighting Technician",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      is_active: true,
      description: "Join the lighting crew."
    )
  end

  test "creates an invitation and a reusable notification atomically" do
    invitation = nil

    assert_difference [ "JobInvitation.count", "Notification.count" ], 1 do
      invitation = JobInvitationCreator.new(job: @job, profile: @profile, invited_by: @owner).call
    end

    notification = @recipient.notifications.find_by!(notifiable: invitation)
    assert_equal "job_invitation", notification.kind
    assert_equal @owner, notification.actor
    assert_equal invitation, notification.notifiable
    assert notification.unread?
  end

  test "rejects invitations for inactive jobs" do
    @job.update!(is_active: false)

    error = assert_raises(ActiveRecord::RecordInvalid) do
      JobInvitationCreator.new(job: @job, profile: @profile, invited_by: @owner).call
    end

    assert_includes error.record.errors[:job], "must be an active published job"
    assert_equal 0, JobInvitation.count
    assert_equal 0, Notification.count
  end

  private

  def create_user(email)
    User.create!(
      first_name: "Test",
      last_name: "User",
      email:,
      password: "password123",
      password_confirmation: "password123"
    )
  end
end
