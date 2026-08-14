require "test_helper"

class CompanyTest < ActiveSupport::TestCase
  test "current plan uses the most recently assigned company plan" do
    company = Company.new
    starter = Plan.new(key: "starter")
    studio = Plan.new(key: "studio")
    company.company_plans.build(plan: starter, created_at: 2.months.ago)
    company.company_plans.build(plan: studio, created_at: 1.month.ago)

    assert_equal studio, company.current_plan
  end

  test "current plan is nil without a plan assignment" do
    assert_nil Company.new.current_plan
  end
end
