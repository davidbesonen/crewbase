require "test_helper"

class Usr::JobInvitationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = create_user("owner-invitations@example.com")
    @recipient = create_user("recipient-invitations@example.com")
    @outsider = create_user("outsider-invitations@example.com")
    [ @owner, @recipient, @outsider ].each { |user| user.visits.create! }
    @profile = @recipient.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @outsider.profiles.create!(profile_type: "user", completed_at: Time.current)
    industry = Industry.create!(name: "Invite Controller")
    @company = Company.create!(name: "Invite Controller Co", contact_email: "invite-controller@example.com", industries: [ industry ])
    CompanyAssignment.create!(company: @company, user: @owner, role: "owner")
    @job = create_job(@company)
  end

  test "company owner invites a profile to an active job" do
    sign_in @owner, scope: :user

    assert_difference [ "JobInvitation.count", "Notification.count" ], 1 do
      post usr_profile_job_invitations_path(@profile), params: { job_invitation: { job_id: @job.id } }
    end

    assert_redirected_to usr_profile_path(@profile)
    assert_equal "Invitation sent.", flash[:notice]
  end

  test "index shows invitations received and sent with their statuses" do
    received = JobInvitationCreator.new(job: @job, profile: @profile, invited_by: @owner).call
    sent_company = Company.create!(
      name: "Recipient Owned Company",
      contact_email: "recipient-owned@example.com",
      industries: @company.industries
    )
    sent_company.company_assignments.create!(user: @recipient, role: "owner")
    sent_job = create_job(sent_company)
    sent = JobInvitationCreator.new(job: sent_job, profile: @outsider.user_profile, invited_by: @recipient).call
    sent.decline!
    sign_in @recipient, scope: :user

    get "/usr/job_invitations"

    assert_response :success
    assert_select "[data-received-invitation='#{received.id}']", text: /Pending/
    assert_select "[data-sent-invitation='#{sent.id}']", text: /Declined/
    assert_select "a[href='#{usr_job_path(@job)}']", text: @job.title
  end

  test "index includes an email invitation addressed to the signed-in user" do
    invitation = JobInvitationCreator.new(job: @job, email: @recipient.email, invited_by: @owner).call
    sign_in @recipient, scope: :user

    get "/usr/job_invitations"

    assert_response :success
    assert_select "[data-received-invitation='#{invitation.id}']"
  end

  test "recipient claims an email invitation when starting an application" do
    invitation = JobInvitationCreator.new(job: @job, email: @recipient.email, invited_by: @owner).call
    sign_in @recipient, scope: :user

    patch accept_usr_job_invitation_path(invitation)

    assert_redirected_to new_usr_job_job_application_path(@job)
    assert_equal @profile, invitation.reload.profile
  end

  test "company owner queues an email invitation from the job posting" do
    sign_in @owner, scope: :user

    assert_no_difference "ActionMailer::Base.deliveries.count" do
      assert_enqueued_with(job: ActionMailer::MailDeliveryJob) do
        assert_difference "JobInvitation.count", 1 do
          post usr_job_job_invitations_path(@job), params: {
            job_invitation: { email: "new.crew@example.com" }
          }
        end
      end
    end

    invitation = JobInvitation.order(:id).last
    assert_equal "new.crew@example.com", invitation.email
    assert_nil invitation.profile
    assert_redirected_to usr_job_path(@job)
  end

  test "non-owner cannot invite an email address" do
    sign_in @outsider, scope: :user

    assert_no_difference "JobInvitation.count" do
      post usr_job_job_invitations_path(@job), params: {
        job_invitation: { email: "new.crew@example.com" }
      }
    end

    assert_response :not_found
  end

  test "profile page offers the owner's active jobs for invitation" do
    draft_job = create_job(@company)
    draft_job.update!(status: :draft)
    sign_in @owner, scope: :user

    get usr_profile_path(@profile)

    assert_response :success
    assert_select "form[action='#{usr_profile_job_invitations_path(@profile)}']" do
      assert_select "option[value='#{@job.id}']", text: /#{Regexp.escape(@job.title)}/
      assert_select "option[value='#{draft_job.id}']", count: 0
    end
  end

  test "non-owner cannot invite a profile" do
    sign_in @outsider, scope: :user

    assert_no_difference [ "JobInvitation.count", "Notification.count" ] do
      post usr_profile_job_invitations_path(@profile), params: { job_invitation: { job_id: @job.id } }
    end

    assert_response :not_found
  end

  test "recipient starts applying without completing the invitation early" do
    invitation = JobInvitationCreator.new(job: @job, profile: @profile, invited_by: @owner).call
    sign_in @recipient, scope: :user

    patch accept_usr_job_invitation_path(invitation)

    assert_redirected_to new_usr_job_job_application_path(@job)
    assert invitation.reload.pending?
    assert_nil invitation.responded_at
  end

  test "recipient declines an invitation" do
    invitation = JobInvitationCreator.new(job: @job, profile: @profile, invited_by: @owner).call
    sign_in @recipient, scope: :user

    patch decline_usr_job_invitation_path(invitation)

    assert_redirected_to usr_job_invitations_path
    assert invitation.reload.declined?
    assert_not_nil invitation.responded_at
  end

  test "another user cannot respond to an invitation" do
    invitation = JobInvitationCreator.new(job: @job, profile: @profile, invited_by: @owner).call
    sign_in @outsider, scope: :user

    patch decline_usr_job_invitation_path(invitation)

    assert_response :not_found
    assert invitation.reload.pending?
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

  def create_job(company)
    Job.create!(
      company:,
      title: "Camera Operator",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      is_active: true,
      description: "Operate camera."
    )
  end
end
