require "test_helper"

class CompanyManagerDashboardTest < ActiveSupport::TestCase
  include ActiveSupport::Testing::TimeHelpers

  test "reports company staffing activity without including another company" do
    travel_to Time.zone.local(2026, 8, 13, 12) do
      company = companies(:one)
      other_company = companies(:two)
      company.company_assignments.create!(user: users(:one), role: "owner")
      company.company_assignments.create!(user: users(:two), role: "member")

      active_job = create_job(company:, title: "Tour manager", starts_at: 5.days.from_now)
      create_job(company:, title: "Archived role", status: :archived, is_active: false)
      create_job(company: other_company, title: "Other company role")
      company.projects.create!(name: "Fall tour", status: :active)
      company.projects.create!(name: "Old tour", status: :completed, archived_at: 1.day.ago)

      accepted = create_application(job: active_job, profile: profiles(:one), status: :accepted, created_at: 2.days.ago)
      create_application(job: active_job, profile: profiles(:two), status: :shortlisted, created_at: Time.current)
      other_job = create_job(company: other_company, title: "Other job")
      create_application(job: other_job, profile: Profile.create!(user: users(:one), profile_type: "user"), status: :submitted)

      create_invitation(job: active_job, status: :pending, email: "pending@example.com", created_at: 1.day.ago)
      create_invitation(job: active_job, status: :accepted, email: "accepted@example.com", created_at: Time.current)

      result = CompanyManagerDashboard.new(company:, today: Date.current).call

      assert_equal({
        company_users: 2,
        active_jobs: 1,
        active_projects: 1,
        applications: 2,
        accepted_hires: 1,
        pending_invitations: 1
      }, result[:summary])
      assert_equal 1, result[:pipeline_counts]["accepted"]
      assert_equal 1, result[:pipeline_counts]["shortlisted"]
      assert_equal 0, result[:pipeline_counts]["submitted"]
      assert_equal({ "pending" => 1, "accepted" => 1, "declined" => 0 }, result[:invitation_counts])
      assert_equal [ active_job ], result[:upcoming_jobs]
      assert_equal({ application_acceptance: 50.0, invitation_acceptance: 50.0 }, result[:rates])

      assert_equal 30, result[:daily_activity].length
      assert_equal({ date: Date.current - 2, applications: 1, invitations: 0 }, result[:daily_activity][-3])
      assert_equal({ date: Date.current - 1, applications: 0, invitations: 1 }, result[:daily_activity][-2])
      assert_equal({ date: Date.current, applications: 1, invitations: 1 }, result[:daily_activity].last)
      assert accepted.persisted?
    end
  end

  test "returns zero rates when there is no activity" do
    result = CompanyManagerDashboard.new(company: companies(:two), today: Date.new(2026, 8, 13)).call

    assert_equal 0.0, result[:rates][:application_acceptance]
    assert_equal 0.0, result[:rates][:invitation_acceptance]
  end

  private

  def create_job(company:, title:, status: :published, is_active: true, starts_at: 2.days.from_now)
    company.jobs.create!(
      title:,
      workplace_type: :remote,
      employment_type: :contract,
      posting_type: :single_role,
      status:,
      is_active:,
      starts_at:,
      description: "A test role"
    )
  end

  def create_application(job:, profile:, status:, created_at: Time.current)
    JobApplication.create!(job:, profile:, status:, created_at:, submitted_at: created_at)
  end

  def create_invitation(job:, status:, email:, created_at:)
    JobInvitation.create!(
      job:,
      invited_by: users(:one),
      status:,
      email:,
      created_at:
    )
  end
end
