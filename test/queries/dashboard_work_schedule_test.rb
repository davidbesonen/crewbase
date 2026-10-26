require "test_helper"

class DashboardWorkScheduleTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @profile = create_profile("Worker")
    @other_profile = create_profile("Other")
    industry = Industry.create!(name: "Schedule Industry")
    @company = Company.create!(name: "Schedule Company", contact_email: "schedule@example.com", industries: [ industry ])
    @company.company_assignments.create!(user: @other_profile.user, role: "owner")
  end

  test "booked work combines accepted applications and crew assignments without duplicates" do
    accepted = create_job("Accepted", status: :filled)
    @profile.job_applications.create!(job: accepted, status: :accepted)
    assigned = create_job("Assigned", posting_type: :multi_position)
    position = assigned.crew_positions.create!(title: "Lighting", headcount: 2)
    position.crew_assignments.create!(profile: @profile)
    @profile.job_applications.create!(job: assigned, status: :accepted)
    position.crew_assignments.create!(profile: @other_profile)
    unrelated = create_job("Other Worker")
    @other_profile.job_applications.create!(job: unrelated, status: :accepted)

    assert_equal [ accepted, assigned ], DashboardWorkSchedule.new(profile: @profile).booked_jobs
  end

  test "applications and invitations alone do not imply a booking" do
    %i[submitted in_review shortlisted rejected withdrawn].each do |status|
      @profile.job_applications.create!(job: create_job(status.to_s), status:)
    end
    %i[pending accepted declined].each do |status|
      JobInvitation.create!(job: create_job("#{status} invitation"), profile: @profile, invited_by: @other_profile.user, status:)
    end

    assert_empty DashboardWorkSchedule.new(profile: @profile).booked_jobs
  end

  test "retains ongoing and closed confirmed work but excludes expired and unavailable job states" do
    ongoing = create_job("Ongoing", starts_at: 2.days.ago, ends_at: 2.days.from_now)
    closed = create_job("Closed", status: :closed, is_active: false)
    excluded = [
      create_job("Finished", starts_at: 2.days.ago, ends_at: 1.day.ago),
      create_job("Past without end", starts_at: 1.day.ago),
      create_job("Undated", starts_at: nil),
      *%i[draft archived completed].map { |status| create_job(status.to_s, status:) }
    ]
    [ ongoing, closed, *excluded ].each { |job| @profile.job_applications.create!(job:, status: :accepted) }

    assert_equal [ ongoing, closed ], DashboardWorkSchedule.new(profile: @profile).booked_jobs
  end

  test "opportunities exclude every booking and owned posting before limiting" do
    4.times do |index|
      @profile.job_applications.create!(job: create_job("Booked #{index}"), status: :accepted)
    end
    own_company = Company.create!(name: "My Company", contact_email: "mine@example.com", industries: @company.industries)
    own_company.company_assignments.create!(user: @profile.user, role: "owner")
    create_job("Owned Posting", company: own_company)
    openings = 4.times.map { |index| create_job("Opening #{index}", starts_at: (index + 2).weeks.from_now) }
    create_job("Past Opening", starts_at: 1.day.ago)
    create_job("Inactive Opening", is_active: false)
    create_job("Draft Opening", status: :draft)

    schedule = DashboardWorkSchedule.new(profile: @profile)

    assert_equal 3, schedule.booked_jobs.size
    assert_equal openings.first(3), schedule.opportunities
  end

  private

  def create_profile(name)
    user = User.create!(first_name: name, last_name: "Schedule", email: "#{name.downcase}-schedule@example.com", password: "password123")
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
  end

  def create_job(title, **attributes)
    Job.create!({
      company: @company,
      title:,
      description: "Schedule test job.",
      workplace_type: :remote,
      employment_type: :contract,
      status: :published,
      is_active: true,
      starts_at: 1.week.from_now
    }.merge(attributes))
  end
end
