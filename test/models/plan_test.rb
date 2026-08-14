require "test_helper"

class PlanTest < ActiveSupport::TestCase
  test "paid workflow labels do not imply Starter loses its project allowance or crew-owned calendar" do
    labels = Plan::COMPANY_FEATURES.values.pluck(:label)

    assert_includes labels, "Multi-position gig staffing"
    assert_includes labels, "Calendar-aware staffing"
    refute_includes labels, "Multi-position gigs and projects"
    refute_includes labels, "Calendar synchronization"
  end
  test "stable beta catalog exposes presentation and entitlement data" do
    plan = Plan.new(key: "starter", name: "Starter", monthly_price_cents: 1900, annual_price_cents: 19000,
      data: { "seats_limit" => 2, "active_jobs_limit" => 3, "projects_limit" => 2,
        "features" => [ "Full crew marketplace", "Live messaging" ] })

    assert_equal "$19", plan.monthly_price
    assert_equal "$190", plan.annual_price
    assert_equal [ "2 company users", "3 active jobs", "2 active projects", "Full crew marketplace", "Live messaging" ], plan.feature_list
  end

  test "presents the same company feature matrix with tier-specific availability" do
    starter = Plan.new(key: "starter")
    studio = Plan.new(key: "studio")

    assert_equal Plan::COMPANY_FEATURES.keys, starter.feature_matrix.map { |feature| feature.fetch(:key) }
    assert_not starter.feature_matrix.find { |feature| feature[:key] == :multi_position_gigs }.fetch(:included)
    assert starter.feature_matrix.find { |feature| feature[:key] == :live_messaging }.fetch(:included)
    assert studio.feature_matrix.all? { |feature| feature.fetch(:included) }
  end

  test "requires a unique stable key" do
    Plan.create!(key: "team", name: "Team", monthly_price_cents: 4900, annual_price_cents: 49000)
    duplicate = Plan.new(key: "team", name: "Other", monthly_price_cents: 9900, annual_price_cents: 99000)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:key], "has already been taken"
  end
end
