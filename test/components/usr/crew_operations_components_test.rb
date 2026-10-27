require "test_helper"

class Usr::CrewOperationsComponentsTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers
  self.fixture_table_names = []

  setup do
    @company = Company.create!(name: "Component Crew", contact_email: "components@example.com", industries: [ Industry.music_touring! ])
  end

  test "import review exposes contact errors and keeps optional data editable" do
    owner = User.create!(first_name: "Component", last_name: "Owner", email: "component-owner@example.com", password: "password123")
    batch = @company.crew_imports.create!(uploaded_by: owner, rows: [ { "first_name" => "A", "last_name" => "Crew", "years_with_company" => "4" } ])
    review = CrewRosterReview.new(company: @company, rows: batch.rows)
    render_inline Usr::CrewImportReviewComponent.new(company: @company, import: batch, review:)
    assert_selector "[role='status']", text: /email or phone/
    assert_selector "input[name='rows[0][years_with_company]'][value='4.0']", visible: :all
    assert_selector "input[name='rows[0][include]'][type='checkbox']"
    assert_button "Add Selected Crew To Roster"
  end

  test "show brief omits tentative contacts and private company notes" do
    job = @company.jobs.create!(title: "Private Music Show", status: :draft, employment_type: :contract, workplace_type: :on_site, posting_type: :multi_position)
    member = @company.crew_members.create!(first_name: "Tentative", last_name: "Person", phone: "6155550190", notes: "Confidential company note")
    position = job.crew_positions.create!(title: "A1", headcount: 1)
    position.crew_holds.create!(crew_member: member)
    render_inline Usr::ShowBriefComponent.new(brief: JobBrief.new(job:))
    assert_no_text "Confidential company note"
    assert_no_text "6155550190"
    assert_no_text "Tentative Person"
    assert_text "No confirmed crew yet"
    assert_button "Print / Save PDF"
  end

  test "review keeps multiline experience and company notes intact" do
    owner = User.create!(first_name: "Multiline", last_name: "Owner", email: "multiline-owner@example.com", password: "password123")
    batch = @company.crew_imports.create!(uploaded_by: owner, rows: [ { "first_name" => "Alex", "last_name" => "Crew", "email" => "multi@example.com", "equipment_text" => "grandMA3\nHog 4", "notes" => "First note\nSecond note" } ])
    review = CrewRosterReview.new(company: @company, rows: batch.rows)
    render_inline Usr::CrewImportReviewComponent.new(company: @company, import: batch, review:)
    assert_selector "textarea[name='rows[0][equipment_text]']", text: "grandMA3\nHog 4", visible: :all
    assert_selector "textarea[name='rows[0][notes]']", text: "First note\nSecond note", visible: :all
  end

  test "import review summarizes people and exposes errors without expanding every valid row" do
    owner = User.create!(first_name: "Review", last_name: "Owner", email: "review-owner@example.com", password: "password123")
    batch = @company.crew_imports.create!(uploaded_by: owner, rows: [
      { "first_name" => "Alex", "last_name" => "Crew", "email" => "ready@example.com", "role" => "Lighting Tech" },
      { "first_name" => "Missing", "last_name" => "Contact", "years_experience" => "bad" }
    ])
    render_inline Usr::CrewImportReviewComponent.new(company: @company, import: batch, review: CrewRosterReview.new(company: @company, rows: batch.rows))
    assert_text "2 people"
    assert_button "Select Ready Rows"
    assert_selector "[data-import-row='2'][data-ready='true'] details:not([open])"
    assert_selector "[data-import-row='3'] details[open]"
    assert_selector "input[type='email'][name='rows[0][email]']", visible: :all
    assert_selector "input[aria-invalid='true'][name='rows[1][years_experience]']"
  end

  test "brief contact details offer direct call and email links" do
    job = @company.jobs.create!(title: "Show", status: :draft, employment_type: :contract, workplace_type: :on_site, production_contact_name: "Production", production_contact_email: "show@example.com", production_contact_phone: "+1 (615) 555-0180")
    render_inline Usr::ShowBriefComponent.new(brief: JobBrief.new(job:))
    assert_link "show@example.com", href: "mailto:show@example.com"
    assert_link "+1 (615) 555-0180", href: "tel:+16155550180"
  end

  test "tour stops offer a useful first step when there are no setups" do
    project = @company.projects.create!(name: "First Tour")
    render_inline Usr::TourStopsFormComponent.new(project:, jobs: [], templates: [], venues: [], stops: [ {} ])
    assert_text "Create Your First Gig Setup"
    assert_link "Create A Gig", href: new_usr_company_job_path(@company, project_id: project.id, audience: "invite_only")
    assert_no_button "Create Draft Tour Stops"
  end

  test "roster search has a recovery action when no people match" do
    render_inline Usr::CrewRosterComponent.new(company: @company, members: [], query: "grandMA3")
    assert_text "No Matching Crew"
    assert_link "Clear Search", href: usr_company_crew_members_path(@company)
    assert_no_text "Bring Your Crew With You"
  end

  test "venue contacts use email and telephone controls" do
    render_inline Usr::VenueFormComponent.new(company: @company, venue: @company.venues.new)
    assert_selector "input[name='venue[contact_email]'][type='email']"
    assert_selector "input[name='venue[contact_phone]'][type='tel']"
  end
end
