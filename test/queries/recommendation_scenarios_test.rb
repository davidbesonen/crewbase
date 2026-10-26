require "test_helper"

# Synthetic acceptance cases, not a claim of measured real-world hiring accuracy.
class RecommendationScenariosTest < ActiveSupport::TestCase
  self.fixture_table_names = []
  SCENARIOS = YAML.safe_load_file(Rails.root.join("test/data/recommendation_scenarios.yml"))

  SCENARIOS.each do |key, scenario|
    test "#{key}: core duties imply capability but equipment needs explicit evidence" do
      owner = member("owner")
      worker = member("worker")
      unconfirmed = member("unconfirmed")
      occupation = Occupation.create!(name: scenario.fetch("occupation"))
      [ worker, unconfirmed ].each { |user| user.user_profile.occupations << occupation }
      worker.user_profile.update!(equipment_family_keys: [ scenario.fetch("equipment") ])
      company = Company.create!(name: "Scenario Company", contact_email: "scenario@example.com", industries: [ Industry.create!(name: scenario.fetch("industry")) ])
      company.company_assignments.create!(user: owner, role: "owner")
      job = company.jobs.create!(title: scenario.fetch("role"), description: "Experienced crew for this production",
        is_active: true, status: :published, employment_type: :contract, workplace_type: :on_site,
        required_capability_keys: [ scenario.fetch("capability") ], required_equipment_family_keys: [ scenario.fetch("equipment") ])

      assert_equal [ job ], WorkerJobRecommender.new(profile: worker.user_profile).results.map(&:job)
      assert_empty WorkerJobRecommender.new(profile: unconfirmed.user_profile).results
      matches = CrewRecommender.new(user: owner, jobs: [ job ], limit: nil).results
      assert_equal worker.user_profile, matches.first.profile
      assert_equal :full, matches.first.tier
      missing_tools = matches.find { |result| result.profile == unconfirmed.user_profile }
      assert_equal :near, missing_tools.tier
      assert_equal 1, missing_tools.gap_reasons.size
      assert_empty worker.user_profile.capability_keys, "Core duties should not require redundant checkboxes"
    end
  end

  private

  def member(name)
    User.create!(first_name: name, last_name: "Scenario", email: "#{name}@scenario.test", password: "password123").tap do |user|
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
    end
  end
end
