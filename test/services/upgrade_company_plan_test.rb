require "test_helper"

class UpgradeCompanyPlanTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    industry = Industry.create!(name: "Plan Upgrade Service")
    @company = Company.create!(name: "Upgrade Service Company", contact_email: "upgrade-service@example.com", industries: [ industry ])
    @starter = create_plan("starter", 1)
    @team = create_plan("team", 2)
    @company.company_plans.create!(plan: @starter, status: "active")
  end

  test "activates a higher plan and retains subscription history" do
    result = UpgradeCompanyPlan.new(company: @company, plan: @team).call

    assert result.success?
    assert_equal @team, CompanyPlanEntitlement.new(@company).current_plan
    assert_equal "replaced", @company.company_plans.find_by!(plan: @starter).status
    assert_equal "active", @company.company_plans.find_by!(plan: @team).status
    assert_equal 2, @company.company_plans.count
  end

  test "rejects the current or a lower tier" do
    result = UpgradeCompanyPlan.new(company: @company, plan: @starter).call

    assert_not result.success?
    assert_equal "Choose a plan above Starter.", result.error
    assert_equal 1, @company.company_plans.count
  end

  private

  def create_plan(key, position)
    Plan.find_or_initialize_by(key:).tap do |plan|
      plan.update!(name: key.titleize, position:, active: true, monthly_price_cents: 1_900 * position, annual_price_cents: 19_000 * position, data: {})
    end
  end
end
