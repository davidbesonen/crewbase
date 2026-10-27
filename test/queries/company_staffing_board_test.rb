require "test_helper"

class CompanyStaffingBoardTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Board", last_name: "Owner", email: "board-owner@example.com", password: "password123")
    @company = Company.create!(name: "Board Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
  end

  test "board keeps tentative roster holds separate from confirmed bookings" do
    assert defined?(CompanyStaffingBoard), "Owners need a company-wide staffing board"
    job = @company.jobs.create!(title: "Festival", status: :published, description: "A show", workplace_type: :on_site, employment_type: :contract, posting_type: :multi_position, starts_at: "2030-06-01", ends_at: "2030-06-02")
    position = job.crew_positions.create!(title: "Stage Tech", headcount: 2)
    member = @company.crew_members.create!(first_name: "Offline", last_name: "Tech", phone: "6155550150")
    position.crew_holds.create!(crew_member: member)
    row = CompanyStaffingBoard.new(company: @company, from: Date.new(2030, 6, 1)).rows.first
    assert_equal 2, row.needed
    assert_equal 0, row.confirmed
    assert_equal 2, row.open_count
    assert_equal 1, row.tentative
    assert_match /Offline Tech/, row.people.map(&:name).join
    assert_equal :unknown, row.people.first.availability_state
  end

  test "private gigs never appear in public discovery but remain available to owners and invitees" do
    assert Job.new.respond_to?(:audience), "Private scheduling must be distinct from public job posting"
    job = @company.jobs.create!(title: "Private show", status: :published, description: "A private production", audience: :invite_only, workplace_type: :on_site, employment_type: :contract)
    assert_not job.publicly_visible?
    assert_not Job.accepting_applications.exists?(job.id)
    assert job.invitable?
  end

  test "single-role gigs can hold roster crew without inventing a multi-position role" do
    assert CrewHold.new.respond_to?(:job), "Single-role gigs also need tentative roster staffing"
    job = @company.jobs.create!(title: "FOH Engineer", description: "Mix the show", audience: :invite_only, status: :published, workplace_type: :on_site, employment_type: :contract, starts_at: "2030-06-01", ends_at: "2030-06-02")
    member = @company.crew_members.create!(first_name: "One", last_name: "Engineer", email: "single-engineer@example.com")
    job.crew_holds.create!(crew_member: member)
    row = CompanyStaffingBoard.new(company: @company, from: "2030-06-01").rows.first
    assert_equal 1, row.tentative
    assert_equal "One Engineer", row.people.first.name
    assert_empty job.crew_positions
  end

  test "owners can find recommended crew for private gigs without exposing them as worker recommendations" do
    occupation = Occupation.create!(name: "Lighting Technician")
    worker = User.create!(first_name: "Lighting", last_name: "Crew", email: "private-lighting@example.com", password: "password123")
    profile = worker.profiles.create!(profile_type: "user", completed_at: Time.current, occupations: [ occupation ])
    job = @company.jobs.create!(title: "Lighting Technician", description: "Run the lights", audience: :invite_only, status: :published, workplace_type: :on_site, employment_type: :contract)
    job.job_requirements.create!(requirement: occupation, importance: :required, source: :employer)
    assert_includes CrewRecommender.new(user: @owner, jobs: [ job ], limit: nil).results.map(&:profile), profile
    assert_empty CrewRecommender.new(user: worker, jobs: [ job ], limit: nil).results
  end

  test "a gig awaiting role setup does not invent an open position" do
    @company.jobs.create!(title: "New tour", status: :draft, posting_type: :multi_position, workplace_type: :on_site, employment_type: :contract)
    board = CompanyStaffingBoard.new(company: @company)
    assert_equal 1, board.summary[:gigs]
    assert_equal 0, board.summary[:open]
    assert_equal 0, board.rows.first.needed
  end
end
