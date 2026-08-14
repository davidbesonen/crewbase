require "test_helper"

class JobCrewSearchTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = create_user("owner")
    industry = Industry.create!(name: "Crew Search Industry")
    @company = Company.create!(name: "Crew Search Co", contact_email: "crew-search@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @occupation = Occupation.create!(name: "A1")
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
