require "test_helper"

class Usr::CompaniesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @user = User.create!(
      first_name: "Company",
      last_name: "Browser",
      email: "company-browser@example.com",
      password: "password123"
    )
    @user.profiles.create!(profile_type: "user", completed_at: Time.current)
    @user.visits.create!
    @industry = Industry.create!(name: "Company Browser Industry")
    sign_in @user, scope: :user
  end

  test "index shows companies and filters by name" do
    alpha = Company.create!(
      name: "Alpha Audio",
      contact_email: "alpha@example.com",
      industries: [ @industry ],
      is_public: true
    )
    Company.create!(
      name: "Beta Broadcast",
      contact_email: "beta@example.com",
      industries: [ @industry ],
      is_public: false
    )

    get usr_companies_path, params: { q: { name_cont: "Alpha" } }

    assert_response :success
    assert_includes response.body, alpha.name
    assert_not_includes response.body, "Beta Broadcast"
    assert_select ".card-accent.card-accent-cyan", minimum: 1
  end

  test "index filters companies by selected industry name" do
    audio = Industry.create!(name: "Audio")
    lighting = Industry.create!(name: "Lighting")

    audio_company = Company.create!(
      name: "Signal Sound",
      contact_email: "signal@example.com",
      industries: [ audio ],
      is_public: true
    )
    Company.create!(
      name: "Beam Works",
      contact_email: "beam@example.com",
      industries: [ lighting ],
      is_public: true
    )

    get usr_companies_path, params: { q: { industries_name_eq: "Audio" } }

    assert_response :success
    assert_includes response.body, audio_company.name
    assert_not_includes response.body, "Beam Works"
  end

  test "search returns matching companies as json" do
    company = Company.create!(
      name: "String Theory",
      contact_email: "string@example.com",
      industries: [ @industry ]
    )

    get search_usr_companies_path, params: { q: "String" }, as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert body.any? { |result| result["id"] == company.id && result["name"] == company.name }
  end

  test "new company form renders industries as a searchable tokenized combobox" do
    get new_usr_company_path

    assert_response :success
    assert_select "#company_industry_ids_combobox[data-controller='taxonomy-multiselect']", count: 1
    assert_select "label[for='company_industry_ids_search']", text: "Industries"
    assert_select "input#company_industry_ids_search[type='search'][role='combobox'][aria-autocomplete='list']", count: 1
    assert_select "#company_industry_ids_options[role='listbox'][aria-multiselectable='true']", count: 1
    assert_select "select[name='company[industry_ids][]'][multiple][data-taxonomy-multiselect-target='select']", visible: false, count: 1
    assert_select "label", text: "Industry ids", count: 0
  end

  test "new company form uses a date-only Founded field" do
    get new_usr_company_path

    assert_response :success
    assert_select "label[for='company_founded_at']", text: "Founded"
    assert_select "input#company_founded_at[type='date']", count: 1
    assert_select "input#company_founded_at[type='datetime-local']", count: 0
  end

  test "new company form offers a mock-data autofill action" do
    company = Company.create!(name: "Existing Owner Company", contact_email: "owner-company@example.com", industries: [ @industry ])
    company.company_assignments.create!(user: @user, role: "owner")

    get new_usr_company_path

    assert_response :success
    assert_select "#company_details_form[data-controller='company-mock-data']", count: 1
    assert_select "button[type='button'][data-action='company-mock-data#fill']", text: /Fill with mock data/
  end

  test "new company form hides mock-data autofill from users without an owner assignment" do
    get new_usr_company_path

    assert_response :success
    assert_select "button[data-action='company-mock-data#fill']", count: 0
  end

  test "owner sees project names in the open jobs table" do
    company = Company.create!(
      name: "Project Jobs Company",
      contact_email: "project-jobs@example.com",
      industries: [ @industry ]
    )
    company.company_assignments.create!(user: @user, role: "owner")
    project = company.projects.create!(name: "Summer Festival", status: :active)
    company.jobs.create!(
      project:,
      title: "Festival A1",
      workplace_type: :on_site,
      employment_type: :contract,
      description: "Mix the festival.",
      status: :published,
      published_at: Time.current
    )

    get usr_company_path(company)

    assert_response :success
    assert_select ".app-hero.app-hero-cyan", count: 1
    assert_select ".card-accent.card-accent-cyan", minimum: 1
    assert_select "#company-jobs th", text: "Project"
    assert_select "#company-jobs td", text: "Summer Festival"
  end

  test "project column is hidden from non-owners" do
    company = Company.create!(
      name: "Public Project Jobs Company",
      contact_email: "public-project-jobs@example.com",
      industries: [ @industry ],
      is_public: true
    )
    project = company.projects.create!(name: "Private Internal Project", status: :active)
    company.jobs.create!(
      project:,
      title: "Public Job",
      workplace_type: :remote,
      employment_type: :contract,
      description: "A public opening.",
      status: :published,
      published_at: Time.current
    )

    get usr_company_path(company)

    assert_response :success
    assert_select "#company-jobs th", text: "Project", count: 0
    assert_select "#company-jobs", text: /Private Internal Project/, count: 0
  end

  test "owner sees only published jobs on the company page and can view all jobs" do
    company = Company.create!(
      name: "Owner Job History Company",
      contact_email: "owner-job-history@example.com",
      industries: [ @industry ]
    )
    company.company_assignments.create!(user: @user, role: "owner")
    published_job = create_job(company, "Published Opening", :published)
    completed_job = create_job(company, "Completed Production", :completed)

    get usr_company_path(company)

    assert_response :success
    assert_select "#company-jobs", text: /#{published_job.title}/
    assert_select "#company-jobs", text: /#{completed_job.title}/, count: 0
    assert_select "#company-jobs a[href='#{usr_company_jobs_path(company)}']", text: "View All Jobs"
  end

  test "non-owner sees only published jobs without the job history link" do
    company = Company.create!(
      name: "Public Job History Company",
      contact_email: "public-job-history@example.com",
      industries: [ @industry ],
      is_public: true
    )
    published_job = create_job(company, "Public Opening", :published)
    completed_job = create_job(company, "Past Public Production", :completed)

    get usr_company_path(company)

    assert_response :success
    assert_select "#company-jobs", text: /#{published_job.title}/
    assert_select "#company-jobs", text: /#{completed_job.title}/, count: 0
    assert_select "#company-jobs a[href='#{usr_company_jobs_path(company)}']", count: 0
  end

  private

  def create_job(company, title, status)
    company.jobs.create!(
      title:,
      workplace_type: :remote,
      employment_type: :contract,
      description: "Company jobs visibility test.",
      status:,
      published_at: status == :published ? Time.current : 1.month.ago
    )
  end
end
