require "test_helper"

class PublicJobInvitationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    owner = create_user("owner-public-invite@example.com")
    industry = Industry.create!(name: "Public Invitations")
    company = Company.create!(name: "Invite Co", contact_email: "invite@example.com", industries: [ industry ])
    CompanyAssignment.create!(company:, user: owner, role: "owner")
    job = Job.create!(
      company:,
      title: "Video Engineer",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      is_active: true,
      description: "Run video systems."
    )
    @invitation = JobInvitation.create!(
      job:,
      invited_by: owner,
      email: "candidate@example.com"
    )
  end

  test "guest invitation page offers account creation and sign in" do
    get public_job_invitation_path(@invitation.token)

    assert_response :success
    assert_select "h1", text: /invited/i
    assert_select "a[href*='sign_up']", text: /create.*account/i
    assert_select "a[href*='sign_in']", text: /sign in/i
  end

  test "sign in returns the recipient to the invitation" do
    user = create_user("candidate@example.com")
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    get public_job_invitation_path(@invitation.token)

    post user_session_path, params: { user: { email: user.email, password: "password123" } }

    assert_redirected_to public_job_invitation_path(@invitation.token)
  end

  test "matching signed-in user claims the invitation and starts applying" do
    user = create_user("candidate@example.com")
    profile = user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    sign_in user, scope: :user

    patch accept_public_job_invitation_path(@invitation.token)

    assert_redirected_to new_usr_job_job_application_path(@invitation.job)
    assert_equal profile, @invitation.reload.profile
    assert @invitation.pending?
  end

  test "a different signed-in email cannot accept the invitation" do
    user = create_user("someone-else@example.com")
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    sign_in user, scope: :user

    patch accept_public_job_invitation_path(@invitation.token)

    assert_response :not_found
    assert @invitation.reload.pending?
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
