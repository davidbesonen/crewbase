require "test_helper"

class CrewRecommenderTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "ranks matching available profiles and limits results to three" do
    owner = create_user("Owner")
    company = create_company(owner)
    occupation = Occupation.create!(name: "Lighting Technician")
    job = create_job(company, title: "Lighting Technician")

    matching_profiles = 4.times.map do |index|
      profile = create_user("Candidate#{index}").profiles.create!(profile_type: "user", completed_at: Time.current)
      profile.occupations << occupation
      profile
    end
    unavailable_profile = create_user("Unavailable").profiles.create!(profile_type: "user", completed_at: Time.current)
    unavailable_profile.occupations << occupation
    unavailable_profile.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "unavailable-for-job",
      from_date: job.starts_at,
      to_date: job.ends_at
    )

    recommendations = CrewRecommender.new(user: owner, companies: [ company ])

    assert recommendations.active_jobs?
    assert_equal 3, recommendations.results.size
    assert recommendations.results.all? { |result| matching_profiles.include?(result.profile) }
    assert recommendations.results.all? { |result| result.job == job }
    assert recommendations.results.all? { |result| result.match_reason == "Matches Lighting Technician" }
    assert recommendations.results.all? { |result| result.availability_label == "Available for job dates" }
    assert_not_includes recommendations.results.map(&:profile), unavailable_profile
  end

  test "reports when owned companies have no active jobs" do
    owner = create_user("Owner")
    company = create_company(owner)

    recommendations = CrewRecommender.new(user: owner, companies: [ company ])

    assert_not recommendations.active_jobs?
    assert_empty recommendations.results
  end

  test "returns all ranked matches when no limit is supplied" do
    owner = create_user("UnlimitedOwner")
    company = create_company(owner)
    occupation = Occupation.create!(name: "Unlimited Lighting Technician")
    create_job(company, title: "Unlimited Lighting Technician")
    4.times do |index|
      profile = create_user("UnlimitedCandidate#{index}").profiles.create!(profile_type: "user", completed_at: Time.current)
      profile.occupations << occupation
    end

    recommendations = CrewRecommender.new(user: owner, companies: [ company ], limit: nil)

    assert_equal 4, recommendations.results.size
  end

  test "recommends for one job and ranks relevant years and rating above extra skill matches" do
    owner = create_user("FocusedOwner")
    company = create_company(owner)
    skill = Skill.create!(name: "Lighting")
    equipment = Equipment.create!(name: "GrandMA3")
    job = create_job(company, title: "Lighting Technician")
    job.update!(description: "Operate Lighting equipment including GrandMA3.")

    experienced = create_user("Experienced").profiles.create!(profile_type: "user", completed_at: Time.current)
    experienced.experiences.create!(
      title: "Lighting Technician",
      company_name: "Touring Co",
      start_year: Date.current.year - 8,
      end_year: Date.current.year
    )
    reviewer = create_user("Reviewer").profiles.create!(profile_type: "user", completed_at: Time.current)
    experienced.received_reviews.create!(profile: reviewer, overall_rating: 4.8)

    keyword_match = create_user("Keywords").profiles.create!(profile_type: "user", completed_at: Time.current)
    keyword_match.skills << skill
    keyword_match.equipment << equipment

    other_job = create_job(company, title: "Audio Engineer")
    recommendations = CrewRecommender.new(user: owner, jobs: [ job ], limit: nil).results

    assert_equal [ experienced, keyword_match ], recommendations.map(&:profile)
    assert recommendations.all? { |result| result.job == job }
    assert_equal 8, recommendations.first.relevant_years
    assert_equal 4.8, recommendations.first.rating
    assert_includes recommendations.second.matched_skills_and_equipment, "Lighting"
    assert_includes recommendations.second.matched_skills_and_equipment, "GrandMA3"
    assert_not_equal other_job, recommendations.first.job
  end

  test "returns all matching recommendations grouped by requested job" do
    owner = create_user("GroupedOwner")
    company = create_company(owner)
    lighting = Occupation.create!(name: "Grouped Lighting Technician")
    audio = Occupation.create!(name: "Grouped Audio Engineer")
    lighting_job = create_job(company, title: "Grouped Lighting Technician")
    audio_job = create_job(company, title: "Grouped Audio Engineer")

    lighting_profile = create_user("GroupedLighting").profiles.create!(profile_type: "user", completed_at: Time.current)
    lighting_profile.occupations << lighting
    audio_profiles = 2.times.map do |index|
      profile = create_user("GroupedAudio#{index}").profiles.create!(profile_type: "user", completed_at: Time.current)
      profile.occupations << audio
      profile
    end

    recommendations = CrewRecommender.new(
      user: owner,
      jobs: [ lighting_job, audio_job ],
      limit: nil
    )

    assert_equal [ lighting_profile ], recommendations.results_for(lighting_job).map(&:profile)
    assert_equal audio_profiles, recommendations.results_for(audio_job).map(&:profile)
  end

  test "uses job or company proximity as a modest ranking factor" do
    owner = create_user("LocationOwner")
    company = create_company(owner)
    occupation = Occupation.create!(name: "Location Lighting Technician")
    company.locations << Location.create!(city: "Nashville", state: "TN", country: "United States")
    job = create_job(company, title: "Location Lighting Technician")

    same_state_profile = create_user("StateCrew").profiles.create!(profile_type: "user", completed_at: Time.current)
    same_state_profile.occupations << occupation
    same_state_profile.locations << Location.create!(city: "Memphis", state: "TN", country: "United States")

    local_profile = create_user("LocalCrew").profiles.create!(profile_type: "user", completed_at: Time.current)
    local_profile.occupations << occupation
    local_profile.locations << Location.create!(city: "Nashville", state: "TN", country: "United States")

    experienced_profile = create_user("ExperiencedCrew").profiles.create!(profile_type: "user", completed_at: Time.current)
    experienced_profile.occupations << occupation
    experienced_profile.locations << Location.create!(city: "Austin", state: "TX", country: "United States")
    experienced_profile.experiences.create!(
      title: "Location Lighting Technician",
      company_name: "Touring Company",
      start_year: Date.current.year - 2,
      end_year: Date.current.year
    )

    recommendations = CrewRecommender.new(user: owner, jobs: [ job ], limit: nil).results

    assert_equal [ experienced_profile, local_profile, same_state_profile ], recommendations.map(&:profile)
  end

  test "uses structured requirements and excludes profiles missing a required taxonomy" do
    owner = create_user("StructuredOwner")
    company = create_company(owner)
    required_occupation = Occupation.create!(name: "A1 Audio Engineer")
    preferred_skill = Skill.create!(name: "Dante")
    prose_only_skill = Skill.create!(name: "GrandMA3")
    job = create_job(company, title: "General live event crew")
    job.update!(description: "GrandMA3 experience is useful.")
    job.job_requirements.create!(requirement: required_occupation, importance: :required)
    job.job_requirements.create!(requirement: preferred_skill, importance: :preferred)

    preferred_match = create_user("StructuredMatch").profiles.create!(profile_type: "user", completed_at: Time.current)
    preferred_match.occupations << required_occupation
    preferred_match.skills << preferred_skill

    required_only = create_user("RequiredOnly").profiles.create!(profile_type: "user", completed_at: Time.current)
    required_only.occupations << required_occupation

    missing_required = create_user("MissingRequired").profiles.create!(profile_type: "user", completed_at: Time.current)
    missing_required.skills << preferred_skill

    prose_only = create_user("ProseOnly").profiles.create!(profile_type: "user", completed_at: Time.current)
    prose_only.skills << prose_only_skill

    results = CrewRecommender.new(user: owner, jobs: [ job ], limit: nil).results

    assert_equal [ preferred_match, required_only, missing_required ], results.map(&:profile)
    assert_equal "Matches A1 Audio Engineer and Dante", results.first.match_reason
    assert_equal [ "Dante" ], results.first.matched_skills_and_equipment
    assert_equal [ :full, :full, :near ], results.map(&:tier)
    assert_equal [ "Missing required A1 Audio Engineer" ], results.last.gap_reasons
  end

  test "places an otherwise matching profile with conflicting dates in the near-match tier" do
    owner = create_user("TierOwner")
    company = create_company(owner)
    occupation = Occupation.create!(name: "Tier Lighting Technician")
    job = create_job(company, title: "Tier Lighting Technician")

    available = create_user("TierAvailable").profiles.create!(profile_type: "user", completed_at: Time.current)
    available.occupations << occupation
    conflicted = create_user("TierConflicted").profiles.create!(profile_type: "user", completed_at: Time.current)
    conflicted.occupations << occupation
    conflicted.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "tier-conflict",
      from_date: job.starts_at,
      to_date: job.starts_at + 1.day
    )

    results = CrewRecommender.new(user: owner, jobs: [ job ], limit: nil).results

    assert_equal [ available, conflicted ], results.map(&:profile)
    assert_equal [ :full, :near ], results.map(&:tier)
    assert_equal [ "Unavailable #{job.starts_at.strftime("%b %-d")} and #{(job.starts_at + 1.day).strftime("%b %-d")}" ],
      results.last.gap_reasons
  end

  test "does not return a profile missing more than one required criterion" do
    owner = create_user("FarOwner")
    company = create_company(owner)
    occupation = Occupation.create!(name: "Far Audio Engineer")
    skill = Skill.create!(name: "Far Dante")
    job = create_job(company, title: "General event crew")
    job.job_requirements.create!(requirement: occupation, importance: :required)
    job.job_requirements.create!(requirement: skill, importance: :required)

    distant_profile = create_user("FarCandidate").profiles.create!(profile_type: "user", completed_at: Time.current)
    distant_profile.experiences.create!(title: "General event crew", company_name: "Crew Co")

    results = CrewRecommender.new(user: owner, jobs: [ job ], limit: nil).results

    assert_not_includes results.map(&:profile), distant_profile
  end

  private

  def create_user(first_name)
    User.create!(
      first_name:,
      last_name: "Crew",
      email: "#{first_name.downcase}-#{SecureRandom.hex(4)}@example.com",
      password: "password123"
    )
  end

  def create_company(owner)
    industry = Industry.create!(name: "Live Events #{SecureRandom.hex(4)}")
    company = Company.create!(
      name: "Crew Company #{SecureRandom.hex(4)}",
      contact_email: "company-#{SecureRandom.hex(4)}@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: owner, role: "owner")
    company
  end

  def create_job(company, title:)
    company.jobs.create!(
      title:,
      description: "Set up lighting systems.",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      is_active: true,
      published_at: Time.current,
      starts_at: 2.weeks.from_now,
      ends_at: 15.days.from_now
    )
  end
end
