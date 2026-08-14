require "test_helper"

class CompanyPlanEntitlementTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    industry = Industry.create!(name: "Entitlement Test Industry")
    @company = Company.create!(
      name: "Entitlement Test Company",
      contact_email: "entitlements@example.com",
      industries: [ industry ]
    )
  end

  test "uses the company's latest plan and answers feature availability" do
    starter = create_plan("starter", seats_limit: 2)
    studio = create_plan("studio", seats_limit: 25)
    @company.company_plans.create!(plan: starter, created_at: 2.days.ago)
    @company.company_plans.create!(plan: studio, created_at: 1.day.ago)

    entitlement = CompanyPlanEntitlement.new(@company)

    assert_equal studio, entitlement.current_plan
    assert_equal "studio", entitlement.tier
    assert entitlement.allowed?(:multi_position_gigs)
    assert entitlement.allowed?(:integrations)
    assert_not entitlement.allowed?(:not_a_real_feature)
  end

  test "ignores newer subscriptions that are not entitled" do
    starter = create_plan("starter", seats_limit: 2)
    studio = create_plan("studio", seats_limit: 25)
    @company.company_plans.create!(plan: starter, status: "active", created_at: 2.days.ago)
    @company.company_plans.create!(plan: studio, status: "incomplete", created_at: 1.day.ago)

    entitlement = CompanyPlanEntitlement.new(@company)

    assert_equal starter, entitlement.current_plan
    assert_equal "starter", entitlement.tier
    refute entitlement.allowed?(:integrations)
  end

  test "exposes normalized limits and current usage" do
    plan = create_plan("starter", seats_limit: 2, active_jobs_limit: 3, projects_limit: 2)
    @company.company_plans.create!(plan:)
    2.times { |index| @company.company_assignments.create!(user: create_user(index), role: "member") }
    2.times { |index| create_job("Active job #{index}") }
    create_job("Draft job", status: :draft)
    @company.projects.create!(name: "Active project", status: :active)
    @company.projects.create!(name: "Completed project", status: :completed)

    entitlement = CompanyPlanEntitlement.new(@company)

    assert_equal 2, entitlement.limit(:company_users)
    assert_equal 3, entitlement.limit(:active_jobs)
    assert_equal 2, entitlement.limit(:active_projects)
    assert_equal 2, entitlement.usage(:company_users)
    assert_equal 2, entitlement.usage(:active_jobs)
    assert_equal 1, entitlement.usage(:active_projects)
    assert_not entitlement.within_limit?(:company_users)
    assert entitlement.within_limit?(:active_jobs)
    assert entitlement.within_limit?(:active_projects)
  end

  test "treats unlimited capacity as unbounded" do
    plan = create_plan("team", active_jobs_limit: "unlimited", projects_limit: "unlimited")
    @company.company_plans.create!(plan:)
    entitlement = CompanyPlanEntitlement.new(@company)

    assert_equal Float::INFINITY, entitlement.limit(:active_jobs)
    assert entitlement.within_limit?(:active_jobs)
    assert entitlement.within_limit?(:active_projects)
  end

  test "fails closed when the company has no plan" do
    entitlement = CompanyPlanEntitlement.new(@company)

    assert_nil entitlement.current_plan
    assert_nil entitlement.tier
    assert_not entitlement.allowed?(:crew_marketplace)
    assert_equal 0, entitlement.limit(:active_jobs)
    assert_equal 0, entitlement.usage(:active_jobs)
    assert_not entitlement.within_limit?(:active_jobs)
  end

  private

  def create_plan(key, **limits)
    Plan.create!(
      key:,
      name: key.titleize,
      monthly_price_cents: 1_900,
      annual_price_cents: 19_000,
      data: limits.stringify_keys
    )
  end

  def create_user(index)
    User.create!(
      first_name: "Member",
      last_name: index.to_s,
      email: "entitlement-member-#{index}@example.com",
      password: "password123"
    )
  end

  def create_job(title, status: :published)
    @company.jobs.create!(
      title:,
      description: "Staff this production.",
      workplace_type: :hybrid,
      employment_type: :contract,
      status:,
      is_active: true,
      published_at: status == :published ? Time.current : nil
    )
  end
end
