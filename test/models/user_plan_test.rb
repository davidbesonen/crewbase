require "test_helper"

class UserPlanTest < ActiveSupport::TestCase
  test "requires a unique catalog slug and nonnegative prices" do
    UserPlan.create!(name: "Crew Pro", slug: "crew-pro", monthly_price_cents: 599, annual_price_cents: 4_900)
    duplicate = UserPlan.new(name: "Other", slug: "crew-pro", monthly_price_cents: -1, annual_price_cents: -1)

    refute duplicate.valid?
    assert_includes duplicate.errors[:slug], "has already been taken"
    assert duplicate.errors[:monthly_price_cents].present?
    assert duplicate.errors[:annual_price_cents].present?
  end
end
