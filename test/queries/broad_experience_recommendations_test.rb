require "test_helper"

class BroadExperienceRecommendationsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Owner", last_name: "Broad", email: "owner-broad@example.com", password: "password123")
    worker = User.create!(first_name: "Worker", last_name: "Broad", email: "worker-broad@example.com", password: "password123")
    @profile = worker.profiles.create!(profile_type: "user", completed_at: Time.current,
      capability_keys: [ "audio" ], equipment_family_keys: [ "audio_systems" ],
      skills_text: "Live sound mixing", equipment_text: "Yamaha CL5")
    company = Company.create!(name: "Broad Productions", contact_email: "broad@example.com", industries: [ Industry.create!(name: "Broad Events") ])
    company.company_assignments.create!(user: @owner, role: "owner")
    @job = company.jobs.create!(title: "Event crew", description: "Live audio mixing",
      workplace_type: :on_site, employment_type: :contract, status: :published, is_active: true,
      required_capability_keys: [ "audio" ], preferred_equipment_family_keys: [ "audio_systems" ])
  end

  test "both recommendation directions use shared categories despite different specific wording" do
    workers = CrewRecommender.new(user: @owner, jobs: [ @job ]).results
    assert_equal [ @profile ], workers.map(&:profile)
    assert_equal :full, workers.first.tier
    assert_includes workers.first.match_reason, "Audio production"
    jobs = WorkerJobRecommender.new(profile: @profile, jobs: [ @job ]).results
    assert_equal [ @job ], jobs.map(&:job)
    assert_equal [ "Audio production", "Audio systems" ], jobs.first.matched_terms
  end

  test "core duties match in both directions without a redundant profile selection" do
    @profile.occupations << Occupation.create!(name: "FOH Engineer")
    @profile.update!(capability_keys: [], equipment_family_keys: [])
    @job.update!(required_capability_keys: [ "foh_mixing" ], preferred_equipment_family_keys: [])
    assert_equal [ @job ], WorkerJobRecommender.new(profile: @profile, jobs: [ @job ]).results.map(&:job)
    assert_equal :full, CrewRecommender.new(user: @owner, jobs: [ @job ]).results.first.tier
    assert_equal [ @profile ], JobCrewSearch.new(job: @job, user: @owner, skill_query: "Front-of-house mixing").results.map(&:profile)
    assert_empty JobCrewSearch.new(job: @job, user: @owner, skill_query: "Monitor mixing").results
    assert_empty @profile.reload.capability_keys
  end

  test "broad familiarity cannot satisfy a different specific product requirement" do
    @job.update!(required_equipment_text: "DiGiCo SD7")
    assert_empty WorkerJobRecommender.new(profile: @profile, jobs: [ @job ]).results
    result = CrewRecommender.new(user: @owner, jobs: [ @job ]).results.first
    assert_equal :near, result&.tier
    assert_equal [ "Missing required DiGiCo SD7" ], result&.gap_reasons
  end

  test "specific details never silently confirm broad capabilities" do
    @profile.update!(capability_keys: [], equipment_family_keys: [])
    assert_empty WorkerJobRecommender.new(profile: @profile, jobs: [ @job ]).results
    assert_equal [ "Audio production" ], ExperienceMatch.new(profile: @profile, job: @job).missing_requirements.map(&:name)
  end

  test "repeated preferred categories do not inflate the score" do
    original = WorkerJobRecommender.new(profile: @profile, jobs: [ @job ]).results.first
    assert original, "A category match must yield a recommendation"
    @job.update!(preferred_capability_keys: [ "audio" ])
    assert_equal original.score, WorkerJobRecommender.new(profile: @profile, jobs: [ @job ]).results.first.score
  end

  test "a specialty matches broad work but unrelated specialties remain explicit gaps" do
    @profile.update!(capability_keys: [ "foh_mixing" ])
    assert_empty ExperienceMatch.new(profile: @profile, job: @job).missing_requirements
    assert WorkerJobRecommender.new(profile: @profile, jobs: [ @job ]).results.any?
    assert_equal :full, CrewRecommender.new(user: @owner, jobs: [ @job ]).results.first.tier
    @job.update!(required_capability_keys: [ "monitor_mixing" ])
    assert_equal [ "Monitor mixing" ], ExperienceMatch.new(profile: @profile, job: @job).missing_requirements.map(&:name)
    assert_empty WorkerJobRecommender.new(profile: @profile, jobs: [ @job ]).results
    assert_equal [ "Missing required Monitor mixing" ], CrewRecommender.new(user: @owner, jobs: [ @job ]).results.first.gap_reasons
  end

  test "requiring both a specialty and its broad category does not double count evidence" do
    @profile.update!(capability_keys: [ "foh_mixing" ])
    @job.update!(required_capability_keys: [ "foh_mixing" ])
    original = WorkerJobRecommender.new(profile: @profile, jobs: [ @job ]).results.first
    assert original
    @job.update!(preferred_capability_keys: [ "audio" ])
    assert_equal original.score, WorkerJobRecommender.new(profile: @profile, jobs: [ @job ]).results.first.score
  end

  test "unstructured postings also avoid counting a specialty and its family twice" do
    profile = Profile.new(capability_keys: [ "foh_mixing" ])
    job = Job.new(title: "Audio production: front-of-house mixing", description: "Live work")
    assert_equal [ "Front-of-house mixing" ], ExperienceMatch.new(profile:, job:).names.fetch("Skill")
  end
end
