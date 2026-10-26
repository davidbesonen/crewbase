require "test_helper"

class AdminManagementTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = member("Owner")
    @owner.roles << Role.find_or_create_by!(name: "app_owner")
    @admin = member("Admin")
    @admin.roles << Role.find_or_create_by!(name: "admin")
    @member = member("Member")
    @company = Company.create!(name: "Admin Test Company", contact_email: "company@example.com", industries: [ Industry.create!(name: "Admin test") ])
    @company.company_assignments.create!(user: @member, role: "owner")
    @job = @company.jobs.create!(title: "Camera operator", description: "Work with the crew", workplace_type: :remote, employment_type: :contract, status: :published)
    sign_in @owner
  end

  test "app owners can access admin and switch between admin and workspace navigation" do
    get "/admin"
    assert_response :success
    assert_select "a[href='#{usr_dashboards_path}']", text: /Workspace/
    get usr_dashboards_path
    assert_select "a[href='/admin']", text: /Site admin/
  end

  test "administrators can inspect linked account company and job details" do
    [ [ "/admin/users/#{@member.id}", @member.email ], [ "/admin/companies/#{@company.id}", @company.name ], [ "/admin/jobs/#{@job.id}", @job.title ] ].each do |path, text|
      get path
      assert_response :success
      assert_includes response.body, text
      assert_select "textarea[name='management[reason]']"
    end
  end

  test "restricting an account revokes an existing session and hides its profile" do
    patch "/admin/users/#{@member.id}", params: { management: { action: "restrict", reason: "Repeated spam after review" } }
    assert_redirected_to "/admin/users/#{@member.id}"
    assert_not @member.reload.active_for_authentication?
    assert_not Profile.network_visible.exists?(@member.user_profile.id)
    sign_in @member
    get usr_dashboards_path
    assert_redirected_to new_user_session_path
  end

  test "a job hold survives owner edits and can be restored with its original status" do
    patch "/admin/jobs/#{@job.id}", params: { management: { action: "restrict", reason: "Misleading posting under investigation" } }
    assert_redirected_to "/admin/jobs/#{@job.id}"
    assert_not @job.reload.accepting_applications?
    assert_not Job.accepting_applications.exists?(@job.id)
    get public_job_posting_path(@job)
    assert_response :not_found
    sign_in @owner
    @job.update!(is_active: true, status: :published)
    assert_not @job.accepting_applications?
    patch "/admin/jobs/#{@job.id}", params: { management: { action: "restore", reason: "Employer corrected the posting" } }
    assert @job.reload.accepting_applications?
    assert_equal 2, AdminAuditEvent.where(subject: @job).count
  end

  test "company restriction removes its public jobs without deleting bookings" do
    patch "/admin/companies/#{@company.id}", params: { management: { action: "restrict", reason: "Company identity review" } }
    assert_redirected_to "/admin/companies/#{@company.id}"
    assert_not Job.accepting_applications.exists?(@job.id)
    assert_not Company.visible_to(nil).exists?(@company.id)
    assert @job.reload.persisted?
  end

  test "reasons are mandatory and members cannot mutate admin records" do
    patch "/admin/jobs/#{@job.id}", params: { management: { action: "restrict", reason: "" } }
    assert_response :unprocessable_entity
    assert @job.reload.accepting_applications?
    sign_in @member
    patch "/admin/jobs/#{@job.id}", params: { management: { action: "restrict", reason: "Unauthorized" } }
    assert_redirected_to usr_dashboards_path
    assert @job.reload.accepting_applications?
  end

  test "only app owners manage administrator roles and protected accounts cannot be suspended" do
    sign_in @admin
    patch "/admin/users/#{@member.id}", params: { management: { action: "grant_admin", reason: "Support staff" } }
    assert_response :unprocessable_entity
    assert_not @member.has_role?("admin")
    sign_in @owner
    patch "/admin/users/#{@member.id}", params: { management: { action: "grant_admin", reason: "Approved support staff" } }
    assert @member.reload.has_role?("admin")
    patch "/admin/users/#{@member.id}", params: { management: { action: "revoke_admin", reason: "Support assignment ended" } }
    assert_redirected_to admin_user_path(@member)
    assert_not @member.reload.has_role?("admin")
    assert @member.has_role?("user")
    patch "/admin/users/#{@owner.id}", params: { management: { action: "restrict", reason: "Self suspension" } }
    assert_response :unprocessable_entity
    assert @owner.reload.active_for_authentication?
  end

  test "audited edits permit only supported fields and roll back invalid changes" do
    patch "/admin/users/#{@member.id}", params: { management: { action: "update_details", reason: "Corrected display name", first_name: "Corrected", email: "hijack@example.com" } }
    assert_redirected_to "/admin/users/#{@member.id}"
    assert_equal "Corrected", @member.reload.first_name
    assert_equal "member-admin-test@example.com", @member.email
    get "/admin/audit_events"
    assert_response :success
    assert_includes response.body, "Corrected display name"
  end

  test "job and company reports link to management records and decisions are audited" do
    sign_in @admin
    @company.update!(is_public: true)
    [ @job, @company ].each do |subject|
      post usr_reports_path, params: { report: { subject_type: subject.class.name, subject_id: subject.id, category: "spam", details: "Misleading claims in this listing" } }
      assert_response :redirect
      report = SafetyReport.order(:id).last
      assert_equal subject, report.subject
      get admin_report_path(report)
      assert_response :success
      assert_select "a[href='#{polymorphic_path([ :admin, subject ])}']", text: /Manage/
      patch admin_report_path(report), params: { moderation_decision: { status: "resolved", notes: "Reviewed and corrected by the owner" } }
      assert_redirected_to admin_report_path(report)
      assert_equal({ "status" => [ "open", "resolved" ] }, AdminAuditEvent.where(subject: report).last.changeset)
    end
  end

  test "private companies and moderated jobs cannot be reported through guessed IDs" do
    @company.update!(is_public: false)
    get new_usr_report_path, params: { subject_type: "Company", subject_id: @company.id }
    assert_response :not_found
    @job.update!(restricted_at: Time.current)
    sign_in @owner
    get new_usr_report_path, params: { subject_type: "Job", subject_id: @job.id }
    assert_response :not_found
  end

  test "suspended profiles cannot receive new invitations even by email" do
    @admin.update!(restricted_at: Time.current)
    sign_in @member
    assert_no_difference "JobInvitation.count" do
      post usr_job_job_invitations_path(@job), params: { job_invitation: { email: @admin.email } }
    end
  end

  test "invalid edits leave records and history unchanged" do
    assert_no_difference "AdminAuditEvent.count" do
      patch admin_user_path(@member), params: { management: { action: "update_details", first_name: "", reason: "Invalid name" } }
      assert_response :unprocessable_entity
    end
    assert_equal "Member", @member.reload.first_name
  end

  test "audit history cannot be edited or destroyed through its model" do
    patch admin_job_path(@job), params: { management: { action: "restrict", reason: "Reviewed spam" } }
    event = AdminAuditEvent.where(subject: @job).last
    assert_raises(ActiveRecord::ReadOnlyRecord) { event.update!(reason: "Rewritten") }
    assert_raises(ActiveRecord::ReadOnlyRecord) { event.destroy! }
    assert_equal @owner, event.actor
  end

  test "billing support filters subscriptions and requires administrator access" do
    plan = Plan.create!(name: "Admin test team", key: "admin_test_team", monthly_price_cents: 1900, annual_price_cents: 19000)
    @company.company_plans.create!(plan: plan, status: "past_due", billing_interval: "monthly")
    get admin_billing_path, params: { status: "past_due", q: @company.name }
    assert_response :success
    assert_includes response.body, "Past due"
    assert_select "a[href='#{admin_company_path(@company)}']", text: @company.name
    sign_in @member
    get admin_billing_path
    assert_redirected_to usr_dashboards_path
    get admin_audit_events_path
    assert_redirected_to usr_dashboards_path
  end

  test "administrative holds prevent new offers without altering existing applications" do
    worker = member("Worker")
    application = @job.job_applications.create!(profile: worker.user_profile)
    attributes = { role: "Camera operator", starts_at: 2.days.from_now, ends_at: 3.days.from_now, rate: 500, currency: "USD", pay_unit: "daily" }
    worker.update!(restricted_at: Time.current)
    result = IssueJobOffer.new(application: application, sender: @member, attributes: attributes).call
    assert_not result.success?
    assert_match(/not available/, result.error)
    worker.update!(restricted_at: nil)
    @company.update!(restricted_at: Time.current)
    result = IssueJobOffer.new(application: application, sender: @member, attributes: attributes).call
    assert_not result.success?
    assert_match(/administrative hold/, result.error)
    assert application.reload.persisted?
    assert_empty application.job_offers
  end

  private

  def member(name)
    User.create!(first_name: name, last_name: "Test", email: "#{name.downcase}-admin-test@example.com", password: "password123").tap do |user|
      user.roles << Role.find_or_create_by!(name: "user")
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
      user.visits.create!
    end
  end
end
