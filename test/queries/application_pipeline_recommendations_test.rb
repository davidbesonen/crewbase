require "test_helper"

class ApplicationPipelineRecommendationsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = create_profile("Owner").user
    @company = Company.create!(
      name: "Recommendation Pipeline Co",
      contact_email: "recommendation-pipeline@example.com",
      industries: [ Industry.create!(name: "Pipeline Recommendations") ]
    )
    @company.company_assignments.create!(user: @owner, role: "owner")
    @occupation = Occupation.create!(name: "Pipeline Lighting Technician")
    @job = create_job(@occupation.name)
  end

  test "includes every matching applicant without the dashboard's three person limit" do
    applications = 4.times.map do |index|
      profile = create_profile("Applicant#{index}")
      profile.occupations << @occupation
      JobApplication.create!(job: @job, profile:)
    end

    results = recommendations(applications)

    assert_equal applications.map(&:id).sort, results.keys.sort
    assert results.values.all? { |result| result.tier == :full && result.job == @job }
    assert_equal "Matches #{@occupation.name}", results.fetch(applications.last.id).match_reason
  end

  test "matches each application to its own job even when the applicant matches another job better" do
    profile = create_profile("MultipleJobs")
    profile.occupations << @occupation
    other_occupation = Occupation.create!(name: "Broadcast Sound Engineer")
    profile.occupations << other_occupation
    profile.experiences.create!(
      title: other_occupation.name,
      company_name: "Event Crew",
      start_year: Date.current.year - 5,
      end_year: Date.current.year
    )
    other_job = create_job(other_occupation.name)
    applications = [ @job, other_job ].map { |job| JobApplication.create!(job:, profile:) }

    results = recommendations(applications)

    assert_equal @job, results.fetch(applications.first.id).job
    assert_equal other_job, results.fetch(applications.last.id).job
    assert_operator results.fetch(applications.last.id).score, :>, results.fetch(applications.first.id).score
  end

  test "does not label near matches with a schedule conflict as recommended" do
    profile = create_profile("Conflicted")
    profile.occupations << @occupation
    profile.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "pipeline-recommendation-conflict",
      from_date: @job.starts_at,
      to_date: @job.ends_at
    )
    application = JobApplication.create!(job: @job, profile:)

    assert_empty recommendations([ application ])
  end

  test "does not label near matches missing a required qualification as recommended" do
    profile = create_profile("MissingQualification")
    profile.occupations << @occupation
    @job.job_requirements.create!(requirement: @occupation, importance: :required)
    @job.job_requirements.create!(requirement: Skill.create!(name: "Pipeline Rigging"), importance: :required)
    application = JobApplication.create!(job: @job, profile:)

    assert_empty recommendations([ application ])
  end

  test "omits recommendations for inactive jobs and incomplete profiles" do
    profile = create_profile("Incomplete")
    profile.occupations << @occupation
    profile.update!(completed_at: nil)
    application = JobApplication.create!(job: @job, profile:)
    assert_empty recommendations([ application ])

    profile.update!(completed_at: Time.current)
    @job.update!(is_active: false)
    assert_empty recommendations([ application ])
  end

  private

  def recommendations(applications)
    ApplicationPipelineRecommendations.new(user: @owner, applications:).by_application_id
  end

  def create_profile(first_name)
    user = User.create!(
      first_name:,
      last_name: "Applicant",
      email: "pipeline-recommendation-#{first_name.downcase}@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
  end

  def create_job(title)
    @company.jobs.create!(
      title:,
      description: "Work with the event crew.",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :published,
      is_active: true,
      starts_at: 2.weeks.from_now,
      ends_at: 15.days.from_now
    )
  end
end
