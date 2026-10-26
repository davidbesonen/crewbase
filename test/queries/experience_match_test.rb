require "test_helper"
require Rails.root.join("db/catalogs/experience_v1")

class ExperienceMatchTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "occupation supplies only core work without confirming neighboring specialties or tools" do
    profile = Profile.new(occupations: [ Occupation.new(name: "FOH Engineer") ])
    job = Job.new(required_capability_keys: [ "foh_mixing", "audio", "monitor_mixing" ], required_equipment_family_keys: [ "mixing_consoles" ])
    match = ExperienceMatch.new(profile:, job:)
    assert_equal [ "Front-of-house mixing" ], match.names.fetch("Skill")
    assert_equal [ "monitor_mixing", "mixing_consoles" ], match.missing_requirements.map(&:category_key)
    assert_empty profile.capability_keys
    assert_empty profile.equipment_family_keys

    profile.occupations = []
    assert_includes ExperienceMatch.new(profile:, job:).missing_requirements.map(&:category_key), "foh_mixing"
  end

  test "ambiguous occupations do not imply a particular technical specialty" do
    profile = Profile.new(occupations: [ Occupation.new(name: "Technical Director") ])
    job = Job.new(required_capability_keys: [ "live_switching", "staging" ])
    assert_equal [ "live_switching", "staging" ], ExperienceMatch.new(profile:, job:).missing_requirements.map(&:category_key)
  end

  test "broad role families can match existing jobs without structured requirements" do
    ExperienceV1.install!
    profile = Profile.new(occupations: [ Occupation.find_by!(category_key: "audio") ])
    job = Job.new(title: "FOH Engineer", description: "Mix live sound for a touring act")
    assert_equal [ "Audio & sound" ], ExperienceMatch.new(profile: profile, job: job).names.fetch("Occupation")
  end

  test "matches shared categories once even when also listed as preferred" do
    category = Skill.create!(name: "Audio production", category_key: "audio")
    profile = Profile.new(skills: [ category ], work_examples: "Mixing on a console")
    job = Job.new(title: "FOH mixer")
    job.job_requirements.build(requirement: category, importance: :required)
    job.job_requirements.build(requirement: category, importance: :preferred)

    match = ExperienceMatch.new(profile: profile, job: job)

    assert_equal [ "Audio production" ], match.names.fetch("Skill")
    assert_empty match.missing_requirements
  end

  test "broad category and free text never satisfy a specific legacy requirement" do
    category = Equipment.create!(name: "Audio systems", category_key: "audio_systems")
    specific = Equipment.create!(name: "Specific Console")
    profile = Profile.new(equipment: [ category ], work_examples: "Specific Console")
    job = Job.new(title: "Audio crew")
    requirement = job.job_requirements.build(requirement: specific, importance: :required)

    match = ExperienceMatch.new(profile: profile, job: job)

    assert_equal [ requirement.requirement.name ], match.missing_requirements.map(&:name)
    assert_empty match.names.fetch("Equipment")
  end

  test "unstructured legacy text matches whole phrases rather than parts of words" do
    profile = Profile.new(skills: [ Skill.new(name: "CAD") ])
    job = Job.new(title: "Academy coordinator")
    assert_empty ExperienceMatch.new(profile: profile, job: job).names.fetch("Skill")
    job.title = "CAD technician"
    assert_equal [ "CAD" ], ExperienceMatch.new(profile: profile, job: job).names.fetch("Skill")
  end
end
