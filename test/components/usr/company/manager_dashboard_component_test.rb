require "test_helper"

class Usr::Company::ManagerDashboardComponentTest < ViewComponent::TestCase
  self.fixture_table_names = []

  test "renders actionable next steps and real dashboard data" do
    company = Company.new(id: 42, name: "Signal Studio")
    plan = Plan.new(key: "studio", name: "Studio")

    render_inline Usr::Company::ManagerDashboardComponent.new(company:, plan:, dashboard: dashboard)

    assert_selector "[data-company-manager-metric='active_jobs']", text: "4"
    {
      company_users: "/usr/companies/42#company-employees",
      active_jobs: "/usr/companies/42/jobs?view=active",
      active_projects: "/usr/companies/42/projects?view=active",
      applications: "/usr/companies/42/applications",
      accepted_hires: "/usr/companies/42/applications?status=accepted",
      pending_invitations: "/usr/job_invitations?company_id=42&status=pending"
    }.each do |key, path|
      assert_selector "a[data-company-manager-metric='#{key}'][href='#{path}']"
      assert_no_selector "a[data-company-manager-metric='#{key}'] a"
    end
    assert_text "Crew roster contacts are separate"
    assert_selector "[data-studio-benefit]", count: 0
    assert_selector "a[href='/usr/companies/42/applications']", text: "Review applications"
    assert_text "Application acceptance"
    assert_text "50%"
    assert_text "Tour A1"
  end

  test "does not claim Studio benefits for another plan" do
    company = Company.new(id: 42, name: "Signal Team")
    plan = Plan.new(key: "team", name: "Team")

    render_inline Usr::Company::ManagerDashboardComponent.new(company:, plan:, dashboard: dashboard)

    assert_selector "[data-studio-benefit]", count: 0
    assert_no_text "Upgrade to Studio"
    assert_text "Next Steps"
  end

  private

  def dashboard
    {
      summary: { company_users: 3, active_jobs: 4, active_projects: 2, applications: 10, accepted_hires: 5, pending_invitations: 2 },
      pipeline_counts: { submitted: 3, in_review: 2, shortlisted: 1, accepted: 5, rejected: 1 },
      invitation_counts: { pending: 2, accepted: 4, declined: 1 },
      daily_activity: [ { date: Date.current, applications: 2, invitations: 1 } ],
      upcoming_jobs: [ Job.new(title: "Tour A1", starts_at: 2.days.from_now, posting_type: :multi_position) ],
      rates: { application_acceptance: 50, invitation_acceptance: 57 }
    }
  end
end
