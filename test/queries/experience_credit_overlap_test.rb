require "test_helper"

class ExperienceCreditOverlapTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "finds a Crewbase Credit from the same company and year" do
    user = User.create!(first_name: "Overlap", last_name: "Worker", email: "overlap@example.com", password: "password123")
    profile = user.profiles.create!(profile_type: "user")
    company = Company.create!(name: "Show Company", contact_email: "show@example.com", industries: [ Industry.create!(name: "Live Events") ])
    credit = profile.credits.create!(company:, role: "A1", project_name: "Arena Show", starts_on: Date.new(2026, 4, 1), verified_at: Time.current)
    experience = profile.experiences.build(company:, title: "Audio Engineer", start_year: "2026", end_year: "2026")

    assert_equal [ credit ], ExperienceCreditOverlap.new(experience:, credits: profile.credits).results
  end

  test "does not flag a long-term role from a different period" do
    user = User.create!(first_name: "Distinct", last_name: "Worker", email: "distinct@example.com", password: "password123")
    profile = user.profiles.create!(profile_type: "user")
    company = Company.create!(name: "Show Company", contact_email: "other-show@example.com", industries: [ Industry.create!(name: "Production") ])
    profile.credits.create!(company:, role: "A1", project_name: "Arena Show", starts_on: Date.new(2026, 4, 1), verified_at: Time.current)
    experience = profile.experiences.build(company:, title: "Staff Engineer", start_year: "2020", end_year: "2022")

    assert_empty ExperienceCreditOverlap.new(experience:, credits: profile.credits).results
  end
end
