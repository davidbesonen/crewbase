require "test_helper"

class Usr::JobPostingPersistenceTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Posting", last_name: "Owner", email: "posting-audit@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Posting audit", contact_email: "audit@example.com", industries: [ Industry.create!(name: "Posting audit") ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    plan = Plan.create!(name: "Team", key: "team_2026", monthly_price_cents: 1900, annual_price_cents: 19000, data: { "active_jobs_limit" => 50 })
    @company.company_plans.create!(plan:)
    @project = @company.projects.create!(name: "Audit tour")
    @occupation = Occupation.find_or_create_by!(name: "Audio Engineer")
    sign_in @owner, scope: :user
  end

  test "every scalar category and named requirement survives create and edit" do
    post usr_company_jobs_path(@company), params: { job: attributes }
    assert_redirected_to usr_project_path(@project)
    job = @company.jobs.order(:id).last
    assert_values(job)
    assert_equal @owner.id, job.created_by
    assert_not job.editable_by_company?
    assert_equal [ @occupation ], job.required_occupations
    assert_equal location_attributes.stringify_keys, job.locations.first.attributes.slice(*location_attributes.keys.map(&:to_s))

    get edit_usr_company_job_path(@company, job)
    assert_response :success
    assert_select "input[name='job[application_deadline]'][value='2027-01-01T18:30']"
    assert_select "input[name='job[starts_at]'][value='2027-01-10T08:30']"
    assert_select "input[name='job[editable_by_company]'][type='checkbox']:not([checked])"
    assert_select "input[name='job[questions][]'][value='Can you travel?']"
    assert_select "textarea[name='job[required_skills_text]']", text: "System tuning"

    patch usr_company_job_path(@company, job), params: { job: attributes.merge(title: "Updated role", editable_by_company: "1", requires_travel: "0", is_active: "0") }
    assert_response :redirect
    job.reload
    assert_equal "Updated role", job.title
    assert job.editable_by_company?
    assert_not job.requires_travel?
    assert_not job.is_active?
    assert_values(job, title: "Updated role", travel: false, active: false)
  end

  test "blank optional fields and deselected requirements really clear previous values" do
    post usr_company_jobs_path(@company), params: { job: attributes }
    job = @company.jobs.order(:id).last
    patch usr_company_job_path(@company, job), params: { job: {
      project_id: "", pay_min: "", pay_max: "", pay_period: "", application_deadline: "", starts_at: "", ends_at: "",
      questions: [ "" ], work_dates: [ "" ], required_occupation_ids: [ "" ],
      required_capability_keys: [ "" ], preferred_capability_keys: [ "" ], required_equipment_family_keys: [ "" ], preferred_equipment_family_keys: [ "" ],
      required_skills_text: "", preferred_skills_text: "", required_equipment_text: "", preferred_equipment_text: "",
      locations_attributes: { "0" => location_attributes.transform_values { "" } }
    } }
    assert_response :redirect
    job.reload
    %i[project_id pay_min pay_max pay_period application_deadline starts_at ends_at].each { |field| assert_nil job.public_send(field), field.to_s }
    %i[questions work_dates required_capability_keys preferred_capability_keys required_equipment_family_keys preferred_equipment_family_keys required_occupations locations].each do |field|
      assert_empty job.public_send(field), field.to_s
    end
    JobExperienceRequirements::TEXT_FIELDS.each_key { |field| assert_equal "", job.public_send(field) }
  end

  test "failed creates and edits retain location and all submitted choices without partially saving" do
    post usr_company_jobs_path(@company), params: { job: attributes.merge(title: "") }
    assert_response :unprocessable_entity
    assert_empty @company.jobs
    assert_select "input[name='job[locations_attributes][0][city]'][value='Chicago']"
    assert_select "input[name='job[locations_attributes][0][address_line_2]'][value='Suite 2']"
    assert_select "input[value='audio'][checked]"
    assert_select "input[name='job[work_dates][]'][value='2027-01-10']"

    post usr_company_jobs_path(@company), params: { job: attributes }
    job = @company.jobs.order(:id).last
    old_location = job.locations.first
    patch usr_company_job_path(@company, job), params: { job: attributes.merge(title: "", locations_attributes: { "0" => location_attributes.merge(city: "Omaha") }) }
    assert_response :unprocessable_entity
    assert_select "input[name='job[locations_attributes][0][city]'][value='Omaha']"
    assert_equal [ old_location.id ], job.reload.locations.ids
    assert_equal "Chicago", old_location.reload.city
    assert_equal "Tour engineer", job.title
  end

  test "location edits never mutate another profile's shared location" do
    post usr_company_jobs_path(@company), params: { job: attributes }
    job = @company.jobs.order(:id).last
    shared = job.locations.first
    @owner.user_profile.locations << shared
    patch usr_company_job_path(@company, job), params: { job: { locations_attributes: { "0" => location_attributes.merge(id: shared.id, city: "Omaha") } } }
    assert_response :redirect
    assert_equal "Omaha", job.reload.locations.first.city
    assert_equal "Chicago", @owner.user_profile.reload.locations.first.city
  end

  test "clearing one address field does not bring back its old value" do
    post usr_company_jobs_path(@company), params: { job: attributes }
    job = @company.jobs.order(:id).last
    patch usr_company_job_path(@company, job), params: { job: { locations_attributes: { "0" => location_attributes.merge(address_line_2: "") } } }
    assert_response :redirect
    assert_nil job.reload.locations.first.address_line_2
    assert_equal "Chicago", job.locations.first.city
  end

  test "creator attribution cannot be supplied or changed by the form" do
    post usr_company_jobs_path(@company), params: { job: attributes.merge(created_by: -123) }
    job = @company.jobs.order(:id).last
    assert_equal @owner.id, job.created_by
    patch usr_company_job_path(@company, job), params: { job: { created_by: -456 } }
    assert_equal @owner.id, job.reload.created_by
  end

  test "the company edit option persists when unchecked and checked" do
    post usr_company_jobs_path(@company), params: { job: attributes }
    job = @company.jobs.order(:id).last
    assert_not job.editable_by_company?
    patch usr_company_job_path(@company, job), params: { job: { editable_by_company: "1" } }
    assert job.reload.editable_by_company?
  end

  test "deadline controls use browser-compatible values after loading and failed validation" do
    post usr_company_jobs_path(@company), params: { job: attributes }
    job = @company.jobs.order(:id).last
    get edit_usr_company_job_path(@company, job)
    assert_select "input[name='job[application_deadline]'][value='2027-01-01T18:30']"
    patch usr_company_job_path(@company, job), params: { job: { title: "", application_deadline: "2027-01-03T17:45" } }
    assert_response :unprocessable_entity
    assert_select "input[name='job[application_deadline]'][value='2027-01-03T17:45']"
  end

  test "optional location does not force a country and missing description gives a visible error" do
    get new_usr_company_job_path(@company)
    assert_select "select[name='job[locations_attributes][0][country]'][required]", count: 0
    post usr_company_jobs_path(@company), params: { job: attributes.merge(description: "") }
    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Description can't be blank/
  end

  test "employment workplace pay and status options all persist" do
    post usr_company_jobs_path(@company), params: { job: attributes }
    job = @company.jobs.order(:id).last
    { employment_type: Job.employment_types.keys, workplace_type: Job.workplace_types.keys, pay_period: Job.pay_periods.keys,
      status: Job.statuses.keys }.each do |field, values|
      values.each do |value|
        patch usr_company_job_path(@company, job), params: { job: { field => value, starts_at: "2025-01-01T08:00", ends_at: "2025-01-02T18:00", work_dates: [ "" ] } }
        assert_response :redirect
        assert_equal value, job.reload.public_send(field), "#{field}=#{value}"
      end
    end
  end

  test "completion validation rolls back location and job changes together" do
    post usr_company_jobs_path(@company), params: { job: attributes }
    job = @company.jobs.order(:id).last
    original_location = job.locations.first
    patch usr_company_job_path(@company, job), params: { job: attributes.merge(title: "Invalid completion", status: "completed",
      locations_attributes: { "0" => location_attributes.merge(city: "Omaha") }) }
    assert_response :unprocessable_entity
    assert_equal "Tour engineer", job.reload.title
    assert_equal [ original_location.id ], job.locations.ids
    assert_select "input[name='job[locations_attributes][0][city]'][value='Omaha']"
  end

  private

  def location_attributes
    { address_line_1: "123 Demo St", address_line_2: "Suite 2", city: "Chicago", state: "IL", zip_code: "60601", country: "United States" }
  end

  def attributes
    { title: "Tour engineer", description: "<p>Mix <strong>live audio</strong>.</p>", posting_type: "single_role", project_id: @project.id,
      employment_type: "contract", workplace_type: "hybrid", status: "published", is_active: "1", requires_travel: "1", editable_by_company: "0",
      pay_min: "450.50", pay_max: "650.75", pay_period: "daily", schedule_has_times: "1", starts_at: "2027-01-10T08:30", ends_at: "2027-01-12T18:45",
      application_deadline: "2027-01-01T18:30", work_dates: [ "2027-01-10", "2027-01-12" ], questions: [ " Can you travel? ", "", "Are you available?" ],
      required_occupation_ids: [ @occupation.id ], required_capability_keys: [ "audio" ], preferred_capability_keys: [ "coordination" ],
      required_equipment_family_keys: [ "audio_systems" ], preferred_equipment_family_keys: [ "vehicles" ],
      required_skills_text: "System tuning", preferred_skills_text: "Tour advancing", required_equipment_text: "Yamaha CL5", preferred_equipment_text: "Wireless Workbench",
      locations_attributes: { "0" => location_attributes } }
  end

  def assert_values(job, title: "Tour engineer", travel: true, active: true)
    assert_equal title, job.title
    assert_equal "Mix live audio.", job.plain_description
    assert_equal @project.id, job.project_id
    assert_equal "single_role", job.posting_type
    assert_equal "contract", job.employment_type
    assert_equal "hybrid", job.workplace_type
    assert_equal "published", job.status
    assert_equal travel, job.requires_travel?
    assert_equal active, job.is_active?
    assert_equal BigDecimal("450.50"), job.pay_min
    assert_equal BigDecimal("650.75"), job.pay_max
    assert_equal "daily", job.pay_period
    assert job.schedule_has_times?
    assert_equal Time.zone.parse("2027-01-10 08:30"), job.starts_at
    assert_equal Time.zone.parse("2027-01-12 18:45"), job.ends_at
    assert_equal Time.zone.parse("2027-01-01 18:30"), job.application_deadline
    assert_equal [ Date.new(2027, 1, 10), Date.new(2027, 1, 12) ], job.work_dates
    assert_equal [ "Can you travel?", "Are you available?" ], job.questions
    %i[required_capability_keys preferred_capability_keys required_equipment_family_keys preferred_equipment_family_keys].each do |field|
      assert_equal attributes[field], job.public_send(field)
    end
    JobExperienceRequirements::TEXT_FIELDS.each_key { |field| assert_equal attributes[field], job.public_send(field) }
  end
end
