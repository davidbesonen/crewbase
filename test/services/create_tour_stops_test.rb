require "test_helper"

class CreateTourStopsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Tour", last_name: "Planner", email: "tour-stops@example.com", password: "password123")
    @company = Company.create!(name: "Stops Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @project = @company.projects.create!(name: "Autumn Tour")
    @job = @company.jobs.create!(title: "Lighting Crew", status: :draft, posting_type: :multi_position, employment_type: :contract, workplace_type: :on_site, starts_at: "2030-06-01", ends_at: "2030-06-02")
    @job.crew_positions.create!(title: "Lighting Tech", headcount: 2)
  end

  test "several tour stops reuse a setup as private drafts with their own venues and dates" do
    assert defined?(CreateTourStops), "Tour owners need to create several dated stops without retyping roles"
    @job.locations.create!(city: "Los Angeles", state: "CA")
    venue = @company.venues.create!(name: "Nashville Hall", city: "Nashville", state: "TN")
    stops = [ { "title" => "Nashville", "starts_on" => "2030-07-01", "venue_id" => venue.id }, { "title" => "Austin", "starts_on" => "2030-07-04" } ]
    assert_difference "Job.count", 2 do
      result = CreateTourStops.new(project: @project, source: @job, actor: @owner, stops:).call
      assert result.success?, result.error
    end
    assert_equal 2, @project.jobs.count
    assert_equal venue, @project.jobs.find_by!(title: "Nashville").venue
    assert_equal "Nashville", @project.jobs.find_by!(title: "Nashville").locations.first.city
    assert_equal Date.new(2030, 7, 5), @project.jobs.find_by!(title: "Austin").ends_at.to_date
    assert @project.jobs.all?(&:draft?)
    assert @project.jobs.all?(&:invite_only?)
  end

  test "an invalid stop rolls back every stop" do
    assert defined?(CreateTourStops), "Tour stop creation must be atomic"
    assert_no_difference "Job.count" do
      result = CreateTourStops.new(project: @project, source: @job, actor: @owner,
        stops: [ { "title" => "Valid", "starts_on" => "2030-07-01" }, { "title" => "Invalid", "starts_on" => "not-a-date" } ]).call
      assert_not result.success?
    end
  end
  test "reused tour setups accept a national catalog venue" do
    entry = VenueCatalogEntry.create!(source_key: "overture/test-stop", name: "National Hall", city: "Nashville", state: "TN", country: "US")
    result = CreateTourStops.new(project: @project, source: @job, actor: @owner,
      stops: [ { "title" => "Nashville", "starts_on" => "2030-07-01", "venue_catalog_entry_id" => entry.id } ]).call
    assert result.success?, result.error
    assert_equal entry, result.jobs.sole.venue&.venue_catalog_entry
    assert_equal "Nashville", result.jobs.sole.locations.sole.city
  end
end
