require "test_helper"

class TrustAndSafetyTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @member, @peer, @admin = %w[member peer admin].map do |name|
      user = User.create!(first_name: name, last_name: "Trust", email: "trust-#{name}@example.com", password: "password123")
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
      user.assignments.create!(role: Role.find_or_create_by!(name: name == "admin" ? "admin" : "user"))
      user.visits.create!
      user
    end
    sign_in @member
  end

  test "unfinished personal profiles are private until completed" do
    @peer.user_profile.update!(completed_at: nil)
    get "/usr/profiles/#{@peer.user_profile.id}"
    assert_response :not_found
    sign_in @peer
    get "/usr/profiles/#{@peer.user_profile.id}"
    assert_response :success
  end

  test "members can submit private reports and admins record an auditable decision" do
    get "/usr/reports/new", params: { subject_type: "Profile", subject_id: @peer.user_profile.id }
    assert_response :success
    post "/usr/reports", params: { report: { subject_type: "Profile", subject_id: @peer.user_profile.id, category: "harassment", details: "Repeated unwanted requests", reporter_id: @peer.id, status: "resolved" } }
    assert_response :redirect
    report = SafetyReport.last
    assert_equal @member, report.reporter
    assert report.open?
    get "/usr/reports"
    assert_select "p", text: "Repeated unwanted requests"
    sign_in @peer
    get "/usr/reports"
    assert_select "p", text: "Repeated unwanted requests", count: 0
    get "/admin/reports"
    assert_response :redirect
    sign_in @admin
    get "/admin/reports/#{report.id}"
    assert_response :success
    patch "/admin/reports/#{report.id}", params: { moderation_decision: { status: "resolved", notes: "Reviewed the account and contacted support." } }
    assert_response :redirect
    assert report.reload.resolved?
    assert_equal @admin, report.moderation_decisions.last.moderator
    assert_equal "open", report.moderation_decisions.last.previous_status
    assert Profile.exists?(@peer.user_profile.id)
  end

  test "report targets must be visible and disputes include own reviews and credits" do
    credit = @peer.user_profile.credits.create!(role: "Operator", project_name: "Private credit", visible: false)
    post "/usr/reports", params: { report: { subject_type: "Credit", subject_id: credit.id, category: "incorrect_credit", details: "Incorrect" } }
    assert_response :not_found
    sign_in @peer
    get "/usr/reports/new", params: { subject_type: "Credit", subject_id: credit.id }
    assert_response :success
    review = Review.create!(profile: @member.user_profile, reviewable: @peer.user_profile, body: "Review to dispute")
    get "/usr/reports/new", params: { subject_type: "Review", subject_id: review.id }
    assert_response :success
    get "/usr/reports/new", params: { subject_type: "User", subject_id: @member.id }
    assert_response :not_found
  end

  test "blocking prevents network contact both ways and unblocking does not restore a connection" do
    connection = NetworkConnection.create!(sender: @peer, recipient: @member, status: :accepted)
    post "/usr/user_blocks", params: { user_block: { profile_id: @peer.user_profile.id } }
    assert_response :redirect
    assert UserBlock.between?(@member, @peer)
    assert connection.reload.declined?
    post "/usr/network_connections", params: { network_connection: { profile_id: @peer.user_profile.id } }
    assert_response :not_found
    sign_in @peer
    post "/usr/network_connections", params: { network_connection: { profile_id: @member.user_profile.id } }
    assert_response :not_found
    sign_in @member
    get "/usr/profiles/#{@peer.user_profile.id}"
    assert_select "a", text: "Connect", count: 0
    assert_select "button", text: /Unblock/
    delete "/usr/user_blocks/#{UserBlock.last.id}"
    assert_response :redirect
    assert_not UserBlock.between?(@member, @peer)
    post "/usr/network_connections", params: { network_connection: { profile_id: @peer.user_profile.id } }
    assert_response :redirect
    assert NetworkConnection.between(@member, @peer).sole.pending?
  end

  test "blocked accounts cannot invite through a profile or matching email" do
    company = Company.create!(name: "Trust Company", contact_email: "trust-company@example.com", industries: [ Industry.create!(name: "Trust Events") ])
    company.company_assignments.create!(user: @peer, role: "owner")
    job = company.jobs.create!(title: "Trust Job", description: "Crew", employment_type: :contract, workplace_type: :on_site, status: :published)
    post "/usr/user_blocks", params: { user_block: { profile_id: @peer.user_profile.id } }
    sign_in @peer
    assert_no_difference "JobInvitation.count" do
      post "/usr/profiles/#{@member.user_profile.id}/job_invitations", params: { job_invitation: { job_id: job.id } }
      assert_response :redirect
      post "/usr/jobs/#{job.id}/job_invitations", params: { job_invitation: { email: @member.email.upcase } }
      assert_response :redirect
    end
    job.update!(posting_type: :multi_position)
    position = job.crew_positions.create!(title: "Crew", headcount: 1)
    shortlist = company.crew_shortlists.create!(name: "Known crew", created_by: @peer)
    shortlist.profiles << @member.user_profile
    assert_no_difference [ "JobApplication.count", "JobOffer.count" ] do
      post "/usr/job_offers", params: { crew_position_id: position.id, profile_id: @member.user_profile.id, job_offer: { role: "Crew", starts_at: 5.days.from_now, ends_at: 6.days.from_now, rate: "300", currency: "USD", pay_unit: "daily" } }
    end
    assert_response :not_found
  end

  test "blocking preserves existing job coordination and private conversation reporting" do
    company = Company.create!(name: "Existing Work", contact_email: "existing-work@example.com", industries: [ Industry.create!(name: "Existing Trust Work") ])
    company.company_assignments.create!(user: @peer, role: "owner")
    job = company.jobs.create!(title: "Existing Call", description: "Crew", employment_type: :contract, workplace_type: :on_site, status: :published)
    application = JobApplication.create!(job: job, profile: @member.user_profile)
    message = ContextualMessageCreator.new(context: application, sender: @peer, body: "Call details").call
    post "/usr/user_blocks", params: { user_block: { profile_id: @peer.user_profile.id } }
    get "/usr/conversations/#{message.conversation_id}"
    assert_response :success
    get "/usr/reports/new", params: { subject_type: "Conversation", subject_id: message.conversation_id }
    assert_response :success
    sign_in @admin
    get "/usr/reports/new", params: { subject_type: "Conversation", subject_id: message.conversation_id }
    assert_response :not_found
    sign_in @admin
    assert_no_difference "UserBlock.count" do
      delete "/usr/user_blocks/#{UserBlock.last.id}"
    end
    assert_response :not_found
  end

  test "company owners can discover and dispute reviews of their company" do
    company = Company.create!(name: "Reviewed Work", contact_email: "reviewed-work@example.com", industries: [ Industry.create!(name: "Review Trust Work") ])
    company.company_assignments.create!(user: @member, role: "owner")
    review = Review.create!(profile: @peer.user_profile, reviewable: company, body: "Company review to dispute")
    get "/usr/reports"
    assert_select "p", text: "Company review to dispute"
    assert_select "a[href*='subject_id=#{review.id}']", text: "Dispute this review"
  end

  test "moderation requires a meaningful decision and keeps history when reopened" do
    post "/usr/reports", params: { report: { subject_type: "Profile", subject_id: @peer.user_profile.id, category: "other", details: "Please review" } }
    report = SafetyReport.last
    sign_in @admin
    patch "/admin/reports/#{report.id}", params: { moderation_decision: { status: "dismissed", notes: "" } }
    assert_response :unprocessable_entity
    assert report.reload.open?
    patch "/admin/reports/#{report.id}", params: { moderation_decision: { notes: "A status is required." } }
    assert_response :unprocessable_entity
    patch "/admin/reports/#{report.id}", params: { moderation_decision: { status: "dismissed", notes: "No supporting evidence available." } }
    patch "/admin/reports/#{report.id}", params: { moderation_decision: { status: "open", notes: "Additional evidence supplied." } }
    assert report.reload.open?
    assert_equal 2, report.moderation_decisions.count
  end
end
