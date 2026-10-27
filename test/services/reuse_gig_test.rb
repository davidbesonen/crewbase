require "test_helper"

class ReuseGigTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Copy", last_name: "Owner", email: "reuse-owner@example.com", password: "password123")
    @company = Company.create!(name: "Reuse Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @job = @company.jobs.create!(title: "Tour Setup", description: "Set up the tour", status: :published, posting_type: :multi_position, workplace_type: :on_site, employment_type: :contract, starts_at: "2030-05-01", ends_at: "2030-05-03", questions: [ "Which console?" ], work_dates: [ Date.new(2030, 5, 1) ])
    @position = @job.crew_positions.create!(title: "Lighting Tech", headcount: 2, pay_min: 300, pay_period: :daily)
  end

  test "duplicate shifts dates and copies roles and requirements without hiring records" do
    assert defined?(ReuseGig), "Owners should be able to reuse an existing gig"
    @job.update!(audience: :invite_only, briefing_notes: "Wear show blacks")
    phase = @job.production_days.create!(date: "2030-05-01", day_type: :load_in, label: "Main stage")
    @position.update!(production_day: phase)
    @job.job_requirements.create!(requirement: Occupation.create!(name: "Lighting Technician"), importance: :required, source: :employer)
    result = ReuseGig.new(source: @job, actor: @owner, title: "Next stop", starts_on: Date.new(2030, 5, 8)).call
    assert result.success?, result.error
    copy = result.job
    assert copy.draft?
    assert copy.invite_only?
    assert_equal "Next stop", copy.title
    assert_equal Date.new(2030, 5, 10), copy.ends_at.to_date
    assert_equal [ Date.new(2030, 5, 8) ], copy.work_dates
    assert_equal [ "Which console?" ], copy.questions
    assert_equal 2, copy.crew_positions.first.headcount
    assert_equal Date.new(2030, 5, 8), copy.crew_positions.first.production_day.date
    assert_equal @job.required_occupations.ids, copy.required_occupations.ids
    assert_empty copy.job_applications
    assert_empty copy.crew_assignments
    assert_empty copy.job_invitations
    assert_nil copy.published_at
  end

  test "saved templates can create a new draft without copying company records" do
    assert defined?(GigTemplate), "Owners should be able to save and reuse a gig template"
    template = GigTemplate.capture!(job: @job, name: "Lighting Package", user: @owner)
    result = ReuseGig.new(source: template, actor: @owner, title: "From template", starts_on: Date.new(2030, 8, 1)).call
    assert result.success?, result.error
    assert_equal "From template", result.job.title
    assert_equal "Lighting Tech", result.job.crew_positions.first.title
    assert_equal Date.new(2030, 8, 1), result.job.starts_at.to_date
  end

  test "reuse rejects other company owners" do
    assert defined?(ReuseGig), "Only the owner may duplicate private gigs"
    outsider = User.create!(first_name: "Other", last_name: "Owner", email: "reuse-other@example.com", password: "password123")
    result = ReuseGig.new(source: @job, actor: outsider).call
    assert_not result.success?
  end

  test "a template remains usable after its saved venue is removed" do
    venue = @company.venues.create!(name: "Former Hall")
    @job.update!(venue:)
    template = GigTemplate.capture!(job: @job, name: "Reusable venue setup", user: @owner)
    venue.destroy!
    result = ReuseGig.new(source: template, actor: @owner, title: "New venue pending").call
    assert result.success?, result.error
    assert_nil result.job.venue_id
  end
end
