require "test_helper"

class PersonalExperienceTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "personal experience matches typed requirements without creating catalog records" do
    before_counts = [ Skill.count, Equipment.count ]
    profile = Profile.new(skills_text: "RF coordination\nPro Tools", equipment_text: "Yamaha CL5")
    job = Job.new(title: "Audio engineer", required_skills_text: "rf COORDINATION", preferred_equipment_text: "yamaha cl5")
    match = ExperienceMatch.new(profile: profile, job: job)

    assert_equal [ "rf COORDINATION" ], match.names.fetch("Skill")
    assert_equal [ "yamaha cl5" ], match.names.fetch("Equipment")
    assert_empty match.missing_requirements
    assert_equal before_counts, [ Skill.count, Equipment.count ]
  end

  test "missing typed requirements are explicit and generic notes do not fulfill them" do
    profile = Profile.new(skills_text: "Mixing", equipment_text: "Audio systems", work_examples: "Yamaha CL5")
    job = Job.new(title: "Engineer", required_equipment_text: "Yamaha CL5")
    assert_equal [ "Yamaha CL5" ], ExperienceMatch.new(profile: profile, job: job).missing_requirements.map(&:name)
  end

  test "clearing personal entries overrides previous selections without deleting historical records" do
    legacy = Skill.create!(name: "Old skill")
    profile = Profile.new(skills: [ legacy ])
    assert_equal [ "Old skill" ], profile.reported_skills
    profile.skills_text = ""
    assert_empty profile.reported_skills
    assert_includes profile.skills, legacy
  end

  test "limits personal entries and rejects oversized entries" do
    profile = Profile.new(skills_text: (1..31).map { |i| "Skill #{i}" }.join("\n"), equipment_text: "x" * 81)
    profile.valid?
    assert profile.errors[:skills_text].present?
    assert profile.errors[:equipment_text].present?
  end
end
