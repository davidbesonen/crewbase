require "test_helper"

class CreditTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "stores an external one-off gig without requiring a Crewbase job" do
    user = User.create!(
      first_name: "Casey",
      last_name: "Crew",
      email: "credit-model@example.com",
      password: "password123"
    )
    profile = user.profiles.create!(profile_type: "user")
    credit = profile.credits.new(
      role: "Lighting Designer",
      project_name: "Summer Sound Festival",
      company_name: "Independent Production",
      starts_on: Date.new(2026, 7, 18),
      ends_on: Date.new(2026, 7, 20),
      location: "Chicago, IL",
      description: "Designed and programmed two stages."
    )

    assert credit.save
    assert_nil credit.job
    assert_equal "Summer Sound Festival", credit.project_name
  end

  test "requires a role and project name and validates the date range" do
    credit = Credit.new(
      starts_on: Date.new(2026, 8, 10),
      ends_on: Date.new(2026, 8, 1)
    )

    assert_not credit.valid?
    assert_includes credit.errors[:role], "can't be blank"
    assert_includes credit.errors[:project_name], "can't be blank"
    assert_includes credit.errors[:ends_on], "must be on or after the start date"
  end
end
