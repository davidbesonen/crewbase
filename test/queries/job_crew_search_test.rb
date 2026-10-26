require "test_helper"

class JobCrewSearchTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = create_user("owner")
    industry = Industry.create!(name: "Crew Search Industry")
    @company = Company.create!(name: "Crew Search Co", contact_email: "crew-search@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @occupation = Occupation.create!(name: "FOH Engineer")
    @skill = Skill.create!(name: "Dante")
    @job = @company.jobs.create!(
      title: "Arena Audio",
      employment_type: :contract,
      workplace_type: :on_site,
      status: :published,
      starts_at: 2.days.from_now,
      ends_at: 3.days.from_now,
      description: "Arena audio crew"
    )
    @job.job_requirements.create!(requirement: @occupation, importance: :required, source: :employer)
    @matching_profile = create_user("matching").user_profile
    @matching_profile.occupations << @occupation
    @matching_profile.skills << @skill
    @matching_profile.calendar_events.create!(
      event_type: "blockout",
      provider: "manual",
      external_id: "later-date",
      from_date: 10.days.from_now,
      to_date: 10.days.from_now
    )
    other_occupation = Occupation.create!(name: "Lighting Director")
    @other_profile = create_user("other").user_profile
    @other_profile.occupations << other_occupation
  end

  test "returns structured matches with explicit availability evidence" do
    results = JobCrewSearch.new(job: @job, user: @owner).results

    assert_equal [ @matching_profile ], results.map(&:profile)
    assert_equal :no_known_conflict, results.first.availability.state
  end

  test "filters job matches by profile taxonomy and availability state" do
    assert_equal [ @matching_profile ],
      JobCrewSearch.new(
        job: @job,
        user: @owner,
        occupation_id: @occupation.id,
        skill_id: @skill.id,
        availability_state: "no_known_conflict"
      ).results.map(&:profile)

    assert_empty JobCrewSearch.new(
      job: @job,
      user: @owner,
      availability_state: "unknown"
    ).results
  end

  test "filters by a personally entered skill and equipment name" do
    @matching_profile.update!(skills_text: "Rare workflow", equipment_text: "Custom console")
    assert_equal [ @matching_profile ], JobCrewSearch.new(job: @job, user: @owner, skill_query: "RARE workflow", equipment_query: "Custom console").results.map(&:profile)
    assert_empty JobCrewSearch.new(job: @job, user: @owner, skill_query: "Unknown skill").results
    assert_empty JobCrewSearch.new(job: @job, user: @owner, skill_id: @skill.id).results
    @matching_profile.update!(capability_keys: [ "audio" ], equipment_family_keys: [ "audio_systems" ])
    assert_equal [ @matching_profile ], JobCrewSearch.new(job: @job, user: @owner, skill_query: "Audio production", equipment_query: "Audio systems").results.map(&:profile)
  end

  test "MA3 is searchable with its common names and works in job recommendations" do
    @matching_profile.update!(equipment_text: "grandMA3 full-size")
    @job.update!(required_equipment_text: "MA3")
    assert_equal [ @matching_profile ], JobCrewSearch.new(job: @job, user: @owner, equipment_query: "MA 3").results.map(&:profile)
    assert_equal [ @job ], WorkerJobRecommender.new(profile: @matching_profile, jobs: [ @job ]).results.map(&:job)
    @matching_profile.update!(equipment_text: "grandMA2", equipment_family_keys: [ "lighting_consoles" ])
    assert_empty JobCrewSearch.new(job: @job, user: @owner, equipment_query: "MA3").results
    assert_empty WorkerJobRecommender.new(profile: @matching_profile, jobs: [ @job ]).results
  end

  private

  def create_user(label)
    User.create!(
      first_name: label.titleize,
      last_name: "Crew",
      email: "#{label}-crew-search@example.com",
      password: "password123"
    ).tap do |user|
      user.profiles.create!(profile_type: "user", completed_at: Time.current)
      user.visits.create!
    end
  end
end
