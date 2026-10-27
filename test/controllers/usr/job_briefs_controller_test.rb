require "test_helper"

class Usr::JobBriefsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Brief", last_name: "Owner", email: "brief-owner@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Brief Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @job = @company.jobs.create!(title: "Live Show", description: "A live concert", status: :published, posting_type: :multi_position, workplace_type: :on_site, employment_type: :contract, starts_at: "2030-06-01", ends_at: "2030-06-03")
    sign_in @owner
  end

  test "production workspace saves reusable venue and show information into a private brief" do
    assert defined?(Usr::JobProductionsController), "Owners need a production workspace"
    assert Rails.application.routes.url_helpers.respond_to?(:usr_job_brief_path), "Gigs need a show-day brief"
    venue = @company.venues.create!(name: "The Hall", city: "Nashville", state: "TN", address: "10 Music St", contact_name: "Stage Manager", contact_phone: "6155550188", load_in_notes: "Use the west dock", parking_notes: "Crew lot B")
    patch usr_job_production_path(@job), params: { job: { venue_id: venue.id, production_contact_name: "Tour Manager", production_contact_phone: "6155550189", briefing_notes: "Wear show blacks" } }
    assert_redirected_to usr_job_production_path(@job)
    assert_equal "Nashville", @job.reload.locations.first.city
    post usr_job_production_days_path(@job), params: { production_day: { date: "2030-06-01", day_type: "load_in", label: "Main Stage", starts_at: "2030-06-01T08:00", ends_at: "2030-06-01T12:00" } }
    assert_redirected_to usr_job_production_path(@job)
    get usr_job_brief_path(@job)
    assert_response :success
    assert_select "[data-show-brief]", text: /Use the west dock/
    assert_select "[data-show-brief]", text: /Tour Manager/
    assert_select "[data-show-brief]", text: /Wear show blacks/
    assert_select "[data-show-brief]", text: /Main Stage/
    assert_select "button", text: "Print / Save PDF"
    assert_not_includes response.body, "@example.com/private"
  end

  test "public posting viewers cannot access the brief or change another company's venue" do
    assert defined?(Usr::JobBriefsController), "Crew need an authorized show brief"
    assert Rails.application.routes.url_helpers.respond_to?(:usr_job_brief_path), "Briefs need separate privacy from public postings"
    worker = User.create!(first_name: "Public", last_name: "Viewer", email: "brief-viewer@example.com", password: "password123")
    sign_in worker
    get usr_job_brief_path(@job)
    assert_response :not_found
    sign_in worker
    patch usr_job_production_path(@job), params: { job: { briefing_notes: "Not allowed" } }
    assert_response :not_found
  end

  test "venue references are limited to the owning company" do
    assert defined?(Usr::JobProductionsController), "Venue selection must belong to the company"
    assert Rails.application.routes.url_helpers.respond_to?(:usr_job_production_path), "Production details need scoped venue selection"
    other = Company.create!(name: "Other Brief Co", contact_email: "other-brief@example.com", industries: @company.industries)
    venue = other.venues.create!(name: "Private Venue")
    patch usr_job_production_path(@job), params: { job: { venue_id: venue.id } }
    assert_response :not_found
    assert_nil @job.reload.venue_id
  end

  test "schedule and shared venue changes notify confirmed crew without altering accepted terms" do
    worker = User.create!(first_name: "Confirmed", last_name: "Crew", email: "brief-booked@example.com", password: "password123")
    profile = worker.profiles.create!(profile_type: "user")
    application = @job.job_applications.create!(profile:, status: :accepted)
    position = @job.crew_positions.create!(title: "A1", headcount: 1)
    offer = application.job_offers.create!(profile:, sender: @owner, crew_position: position, role: "A1", starts_at: "2030-06-01T07:00", ends_at: "2030-06-01T23:00", rate: 300, currency: "USD", pay_unit: "daily", status: :accepted)
    assert_difference "worker.notifications.count", 1 do
      post usr_job_production_days_path(@job), params: { production_day: { date: "2030-06-01", day_type: "load_in", label: "Dock opens" } }
    end
    venue = @company.venues.create!(name: "Changing Venue")
    @job.update!(venue:)
    assert_difference "worker.notifications.count", 1 do
      patch usr_company_venue_path(@company, venue), params: { venue: { parking_notes: "Use the east lot" } }
    end
    assert_equal "A1", offer.reload.role
    assert_equal Time.zone.parse("2030-06-01T07:00"), offer.starts_at
    assert offer.accepted?
  end

  test "invalid schedule entries keep entered details and errors in the workspace" do
    post usr_job_production_days_path(@job), params: { production_day: { date: "2030-05-01", day_type: "load_in", label: "Keep my dock instructions", notes: "Meet at the west gate" } }
    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /within the gig dates/
    assert_select "input[name='production_day[label]'][value='Keep my dock instructions']"
    assert_select "textarea[name='production_day[notes]']", text: "Meet at the west gate"
    assert_empty @job.production_days

    day = @job.production_days.create!(date: "2030-06-01", day_type: "show", label: "Original")
    patch usr_job_production_day_path(@job, day), params: { production_day: { date: "2030-06-01", label: "My correction", starts_at: "2030-06-01T15:00", ends_at: "2030-06-01T14:00" } }
    assert_response :unprocessable_entity
    assert_select "details[open] input[value='My correction']"
    assert_equal "Original", day.reload.label
  end
end
