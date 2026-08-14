require "test_helper"

class WorkerJobRecommenderTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "ranks active published jobs by worker occupations skills equipment and location" do
    profile = create_worker("Worker")
    profile.occupations << Occupation.create!(name: "Lighting Technician")
    profile.skills << Skill.create!(name: "Lighting Design")
    profile.equipment << Equipment.create!(name: "GrandMA3")
    profile.locations << Location.create!(city: "Chicago", state: "IL", country: "United States")

    company = create_company("Match Company")
    strongest = create_job(
      company,
      title: "Lighting Technician",
      description: "Lead lighting design with GrandMA3.",
      location: Location.create!(city: "Chicago", state: "IL", country: "United States")
    )
    occupation_only = create_job(company, title: "Lighting Technician", description: "Join our touring team.")
    create_job(company, title: "Audio Engineer", description: "Mix live audio.")
    create_job(company, title: "Draft Lighting Technician", description: "Lighting Design", status: :draft)
    create_job(company, title: "Inactive Lighting Technician", description: "Lighting Design", is_active: false)

    results = WorkerJobRecommender.new(profile:, limit: nil).results

    assert_equal [ strongest, occupation_only ], results.map(&:job)
    assert_equal [ "Lighting Technician", "Lighting Design", "GrandMA3" ], results.first.matched_terms
    assert_includes results.first.match_reasons, "Matches Lighting Technician, Lighting Design, and GrandMA3"
    assert_includes results.first.match_reasons, "Located in Chicago, IL"
  end

  test "excludes jobs that conflict with worker blockout dates" do
    profile = create_worker("Unavailable")
    profile.occupations << Occupation.create!(name: "Camera Operator")
    company = create_company("Date Company")
    conflicting = create_job(company, title: "Camera Operator", description: "Operate a camera.")
    available = create_job(
      company,
      title: "Camera Operator",
      description: "Operate a camera later.",
      starts_at: 4.weeks.from_now,
      ends_at: 5.weeks.from_now
    )
    profile.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "worker-conflict",
      from_date: conflicting.starts_at,
      to_date: conflicting.ends_at
    )

    results = WorkerJobRecommender.new(profile:, limit: nil).results

    assert_equal [ available ], results.map(&:job)
    assert_equal "Available for job dates", results.first.availability_label
  end

  test "adds transparent remote compensation and date reasons" do
    profile = create_worker("Remote")
    profile.skills << Skill.create!(name: "Production Coordination")
    company = create_company("Remote Company")
    job = create_job(
      company,
      title: "Production Coordinator",
      description: "Production coordination for a remote team.",
      workplace_type: :remote,
      pay_min: 500,
      pay_max: 700,
      pay_period: :daily
    )

    result = WorkerJobRecommender.new(profile:).results.first

    assert_equal job, result.job
    assert_includes result.match_reasons, "Remote role"
    assert_includes result.match_reasons, "$500.00 - $700.00 daily"
    assert_includes result.match_reasons, "Available for job dates"
  end

  test "does not recommend jobs at companies the worker owns" do
    profile = create_worker("Owner")
    profile.occupations << Occupation.create!(name: "Stage Manager")
    company = create_company("Owned Company")
    company.company_assignments.create!(user: profile.user, role: "owner")
    create_job(company, title: "Stage Manager", description: "Manage the stage.")

    assert_empty WorkerJobRecommender.new(profile:).results
  end

  test "uses structured requirements and excludes jobs whose required taxonomy is missing" do
    profile = create_worker("Structured")
    occupation = Occupation.create!(name: "A1 Audio Engineer")
    preferred_skill = Skill.create!(name: "Dante")
    prose_skill = Skill.create!(name: "GrandMA3")
    profile.occupations << occupation
    profile.skills << preferred_skill
    profile.skills << prose_skill
    company = create_company("Structured Company")

    matching = create_job(company, title: "General crew", description: "GrandMA3 is useful.")
    matching.job_requirements.create!(requirement: occupation, importance: :required)
    matching.job_requirements.create!(requirement: preferred_skill, importance: :preferred)

    missing_required = create_job(company, title: "Audio crew", description: "Dante experience preferred.")
    missing_required.job_requirements.create!(
      requirement: Occupation.create!(name: "A2 Audio Engineer"),
      importance: :required
    )

    results = WorkerJobRecommender.new(profile:, limit: nil).results

    assert_equal [ matching ], results.map(&:job)
    assert_equal [ "A1 Audio Engineer", "Dante" ], results.first.matched_terms
    assert_includes results.first.match_reasons, "Matches A1 Audio Engineer and Dante"
    assert_not_includes results.first.matched_terms, "GrandMA3"
  end

  private

  def create_worker(first_name)
    user = User.create!(
      first_name:,
      last_name: "Crew",
      email: "#{first_name.downcase}-#{SecureRandom.hex(4)}@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
  end

  def create_company(name)
    industry = Industry.create!(name: "#{name} Industry")
    Company.create!(
      name:,
      contact_email: "#{name.parameterize}-#{SecureRandom.hex(4)}@example.com",
      industries: [ industry ]
    )
  end

  def create_job(company, title:, description:, location: nil, starts_at: 2.weeks.from_now,
    ends_at: 3.weeks.from_now, workplace_type: :on_site, status: :published, is_active: true,
    pay_min: nil, pay_max: nil, pay_period: nil)
    job = company.jobs.create!(
      title:,
      description:,
      workplace_type:,
      employment_type: :contract,
      status:,
      is_active:,
      published_at: Time.current,
      starts_at:,
      ends_at:,
      pay_min:,
      pay_max:,
      pay_period:
    )
    job.locations << location if location
    job
  end
end
