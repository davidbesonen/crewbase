require "test_helper"

class Usr::ProductionPlanningFlowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Production", last_name: "Owner", email: "planning-owner@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Planning Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @job = @company.jobs.create!(title: "Festival", description: "Staff the festival", status: :published, posting_type: :multi_position, workplace_type: :on_site, employment_type: :contract, starts_at: "2030-06-01", ends_at: "2030-06-03")
    @position = @job.crew_positions.create!(title: "Lighting Tech", headcount: 2)
    sign_in @owner
  end

  test "company planning board shows roles and accepts private roster holds" do
    assert Rails.application.routes.url_helpers.respond_to?(:usr_company_staffing_path), "Owners need a company planning board"
    member = @company.crew_members.create!(first_name: "Alex", last_name: "Offline", phone: "6155550170")
    get usr_company_staffing_path(@company, from: "2030-06-01")
    assert_response :success
    assert_select "[data-staffing-position='#{@position.id}']", text: /Lighting Tech/
    assert_difference "CrewHold.count", 1 do
      post usr_crew_position_crew_holds_path(@position), params: { crew_member_id: member.id }
    end
    assert_redirected_to usr_company_staffing_path(@company, from: "2030-06-01")
    get usr_company_staffing_path(@company, from: "2030-06-01")
    assert_select "[data-staffing-position='#{@position.id}']", text: /Alex Offline/
    assert_select "[data-staffing-position='#{@position.id}']", text: /0 confirmed/
  end

  test "owners can duplicate and save templates through scoped forms" do
    assert Rails.application.routes.url_helpers.respond_to?(:new_usr_company_gig_reuse_path), "Gig reuse needs a clear owner workflow"
    assert_difference "Job.count", 1 do
      post usr_company_gig_reuses_path(@company), params: { source_job_id: @job.id, title: "Next venue", starts_on: "2030-07-01" }
    end
    copy = @company.jobs.order(:id).last
    assert_redirected_to edit_usr_company_job_path(@company, copy)
    assert copy.draft?
    assert_difference "GigTemplate.count", 1 do
      post usr_company_gig_templates_path(@company), params: { source_job_id: @job.id, name: "Festival crew" }
    end
    assert_redirected_to usr_company_gig_templates_path(@company)
    get usr_company_gig_templates_path(@company)
    assert_select "a", text: "Use Template"
  end

  test "private published gigs are available only to owners and invited workers" do
    @job.update!(audience: :invite_only)
    sign_out @owner
    get public_job_posting_path(@job)
    assert_response :not_found
    worker = User.create!(first_name: "Tour", last_name: "Worker", email: "private-gig-worker@example.com", password: "password123", onboarding_completed_at: Time.current)
    worker.profiles.create!(profile_type: "user", completed_at: Time.current)
    sign_in worker
    get usr_job_path(@job)
    assert_response :not_found
    JobInvitationCreator.new(job: @job, invited_by: @owner, profile: worker.user_profile).call
    sign_in worker
    get usr_job_path(@job)
    assert_response :success
    get new_usr_job_job_application_path(@job)
    assert_response :success
  end

  test "a project can create dated tour stops from one existing setup" do
    assert Rails.application.routes.url_helpers.respond_to?(:new_usr_project_tour_stops_path), "Projects need a bulk tour stop workflow"
    project = @company.projects.create!(name: "Tour Route")
    get new_usr_project_tour_stops_path(project)
    assert_response :success
    assert_select "input[name='stops[0][starts_on]']"
    assert_difference "Job.count", 2 do
      post usr_project_tour_stops_path(project), params: { source_job_id: @job.id, stops: {
        "0" => { title: "Austin", starts_on: "2030-07-01" }, "1" => { title: "Dallas", starts_on: "2030-07-03" }
      } }
    end
    assert_redirected_to usr_project_path(project)
    assert_equal 2, project.jobs.count
  end

  test "board navigation keeps filters and starts private staffing without making public posting private" do
    get usr_company_staffing_path(@company, from: "2030-06-01", q: "Festival")
    assert_select "a[href='#{usr_company_staffing_path(@company, from: '2030-06-29', q: 'Festival')}']", text: "Next Four Weeks"
    assert_select "a[href='#{new_usr_company_job_path(@company, audience: 'invite_only')}']", text: "Create Gig"
    get new_usr_company_job_path(@company, audience: "invite_only")
    assert_select "select[name='job[audience]'] option[value='invite_only'][selected]"
    assert_select "button[name='publication_action'][value='publish']", text: "Activate Private Gig"
    get new_usr_company_job_path(@company)
    assert_select "select[name='job[audience]'] option[value='public_listing'][selected]"
  end

  test "tour stop submission without a setup keeps the stops for correction" do
    project = @company.projects.create!(name: "Setup Recovery")
    post usr_project_tour_stops_path(project), params: { stops: { "0" => { title: "Austin", starts_on: "2030-07-01" } } }
    assert_response :unprocessable_entity
    assert_select "input[value='Austin']"
    assert_select ".alert", text: /Choose a gig or template/
  end

  test "selecting a catalog venue creates a company copy and preserves private notes on reuse" do
    entry = VenueCatalogEntry.create!(source_key: "way/99", name: "National Music Hall", city: "Austin", state: "TX", country: "US", address: "100 Music Lane")
    assert_difference "@company.venues.count", 1 do
      patch usr_job_production_path(@job), params: { venue_catalog_entry_id: entry.id, job: { briefing_notes: "Arrive early" } }
    end
    assert_redirected_to usr_job_production_path(@job)
    venue = @job.reload.venue
    assert_equal entry, venue.venue_catalog_entry
    assert_equal "Austin", @job.locations.sole.city
    venue.update!(load_in_notes: "Private loading entrance", contact_email: "private@example.com")
    assert_no_difference "Venue.count" do
      patch usr_job_production_path(@job), params: { venue_catalog_entry_id: entry.id, job: { briefing_notes: "Updated" } }
    end
    assert_equal "Private loading entrance", venue.reload.load_in_notes
    assert_equal "private@example.com", venue.contact_email
  end
end
