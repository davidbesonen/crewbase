require "test_helper"

class InstallPricingCatalogTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "installs two affordable company tiers and retires crew sales without changing legacy prices" do
    legacy = Plan.create!(key: "team", name: "Team", active: true, monthly_price_cents: 4900, annual_price_cents: 49000, stripe_monthly_price_id: "price_legacy")
    crew = UserPlan.create!(name: "Crew Pro", slug: "crew-pro", active: true, monthly_price_cents: 599, annual_price_cents: 4900)
    assert defined?(InstallPricingCatalog), "A shared launch catalog installer is needed"
    2.times { InstallPricingCatalog.new.call }
    assert_equal %w[free team_2026], Plan.active.pluck(:key)
    assert_equal [ 0, 1900 ], Plan.active.pluck(:monthly_price_cents)
    assert_equal [ 0, 19000 ], Plan.active.pluck(:annual_price_cents)
    assert_equal 4900, legacy.reload.monthly_price_cents
    assert_equal "price_legacy", legacy.stripe_monthly_price_id
    assert_not legacy.active?
    assert_not crew.reload.active?
    assert_nil Plan.find_by!(key: "team_2026").stripe_monthly_price_id
  end
end
