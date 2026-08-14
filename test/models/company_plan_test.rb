require "test_helper"

class CompanyPlanTest < ActiveSupport::TestCase
  test "only active and trialing subscriptions are entitled" do
    assert CompanyPlan.new(status: "active").entitled?
    assert CompanyPlan.new(status: "trialing").entitled?
    refute CompanyPlan.new(status: "incomplete").entitled?
    refute CompanyPlan.new(status: "past_due").entitled?
    refute CompanyPlan.new(status: "canceled").entitled?
  end

  test "validates provider-backed subscription attributes" do
    company_plan = CompanyPlan.new(status: "unknown", billing_interval: "weekly")

    refute company_plan.valid?
    assert_includes company_plan.errors[:status], "is not included in the list"
    assert_includes company_plan.errors[:billing_interval], "is not included in the list"
  end
end
