require "test_helper"

class CompanyAssignmentTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "a company cannot add users beyond its plan capacity" do
    industry = Industry.create!(name: "Company capacity")
    company = Company.create!(name: "Capacity Company", contact_email: "capacity@example.com", industries: [ industry ])
    plan = Plan.create!(
      key: "starter",
      name: "Starter",
      monthly_price_cents: 1_900,
      annual_price_cents: 19_000,
      data: { "seats_limit" => 2 }
    )
    company.company_plans.create!(plan:)
    2.times do |index|
      user = User.create!(first_name: "User", last_name: index.to_s, email: "capacity-#{index}@example.com", password: "password123")
      company.company_assignments.create!(user:, role: index.zero? ? "owner" : "member")
    end

    extra_user = User.create!(first_name: "Extra", last_name: "User", email: "capacity-extra@example.com", password: "password123")
    assignment = company.company_assignments.new(user: extra_user, role: "member")

    assert_not assignment.save
    assert_includes assignment.errors[:base], "Starter plan allows 2 company users"
  end

  test "legacy companies without a plan can retain company users" do
    industry = Industry.create!(name: "Legacy capacity")
    company = Company.create!(name: "Legacy Company", contact_email: "legacy-capacity@example.com", industries: [ industry ])
    user = User.create!(first_name: "Legacy", last_name: "Owner", email: "legacy-capacity-user@example.com", password: "password123")

    assert company.company_assignments.create(user:, role: "owner").persisted?
  end
end
