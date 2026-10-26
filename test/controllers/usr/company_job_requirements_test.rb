require "test_helper"

class Usr::CompanyJobRequirementsTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = User.create!(
      first_name: "Job",
      last_name: "Owner",
      email: "job-requirements-owner@example.com",
      password: "password123"
    )
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!

    industry = Industry.create!(name: "Job Requirements Industry")
    @company = Company.create!(
      name: "Requirements Company",
      contact_email: "requirements-company@example.com",
      industries: [ industry ]
    )
    @company.company_assignments.create!(user: @owner, role: "owner")
    team = Plan.create!(
      key: "team",
      name: "Team Requirements",
      monthly_price_cents: 4_900,
      annual_price_cents: 49_000,
      data: { "seats_limit" => 8, "active_jobs_limit" => 15, "projects_limit" => "unlimited" }
    )
    @company.company_plans.create!(plan: team)
    @occupation = Occupation.find_or_create_by!(name: "FOH Engineer")
    @required_skill = Skill.create!(name: "Dante")
    @preferred_skill = Skill.create!(name: "Yamaha CL")
    @equipment = Equipment.create!(name: "QL5")
    sign_in @owner, scope: :user
  end

  test "stores broad requirements separately from named product requirements" do
    post usr_company_jobs_path(@company), params: { job: valid_job_attributes.merge(
      required_capability_keys: [ "audio" ], preferred_equipment_family_keys: [ "audio_systems" ],
      required_equipment_text: "Yamaha CL5"
    ) }
    assert_response :redirect
    job = Job.order(:id).last
    assert_equal [ "audio" ], job.attributes["required_capability_keys"]
    assert_equal [ "audio_systems" ], job.attributes["preferred_equipment_family_keys"]
    assert_equal "Yamaha CL5", job.required_equipment_text
    get edit_usr_company_job_path(@company, job)
    assert_select "input[name='job[required_capability_keys][]'][value='audio'][checked]"
    assert_select "input[name='job[preferred_equipment_family_keys][]'][value='audio_systems'][checked]"
  end

  test "existing job occupations tailor both required and preferred category choices" do
    occupation = Occupation.create!(name: "Lighting Technician")
    job = @company.jobs.create!(valid_job_attributes)
    job.job_requirements.create!(requirement: occupation, importance: :required)
    get edit_usr_company_job_path(@company, job)
    assert_response :success
    assert_select "[data-category-primary] input[name='job[required_capability_keys][]'][value='lighting_programming']"
    assert_select "[data-category-primary] input[name='job[preferred_capability_keys][]'][value='lighting_programming']"
    assert_select "[data-category-row][hidden] input[value='lighting'][disabled]", count: 2
    assert_select "[data-category-other] input[name='job[required_capability_keys][]'][value='audio']"
  end

  test "owner creates a job with structured required and preferred requirements" do
    post usr_company_jobs_path(@company), params: {
      job: valid_job_attributes.merge(
        required_occupation_ids: [ @occupation.id ],
        required_skill_ids: [ @required_skill.id ],
        preferred_skill_ids: [ @preferred_skill.id ],
        preferred_equipment_ids: [ @equipment.id ]
      )
    }

    job = Job.order(:id).last
    assert_redirected_to usr_company_path(@company)
    assert_equal [ @occupation ], job.required_occupations
    assert_equal [ @required_skill ], job.required_skills
    assert_equal [ @preferred_skill ], job.preferred_skills
    assert_equal [ @equipment ], job.preferred_equipment
  end

  test "owner replaces structured requirements when editing a job" do
    replacement = Skill.create!(name: "Wireless Workbench")
    job = @company.jobs.create!(valid_job_attributes)
    job.job_requirements.create!(
      requirement: @required_skill,
      importance: :required,
      source: :employer,
      confirmed_at: Time.current
    )

    patch usr_company_job_path(@company, job), params: {
      job: valid_job_attributes.merge(
        required_skill_ids: [ replacement.id ],
        preferred_skill_ids: [ "" ]
      )
    }

    assert_redirected_to usr_company_path(@company)
    assert_equal [ replacement ], job.reload.required_skills
    assert_empty job.preferred_skills
  end

  test "job form keeps occupations and accepts employer-written skills and equipment" do
    get new_usr_company_job_path(@company)
    assert_select "#job_required_occupation_ids option[value='#{@occupation.id}']"
    assert_select "textarea[name='job[required_skills_text]']"
    assert_select "textarea[name='job[preferred_skills_text]']"
    assert_select "textarea[name='job[required_equipment_text]']"
    assert_select "textarea[name='job[preferred_equipment_text]']"
    assert_select "select[name='job[required_equipment_ids][]']", count: 0
  end

  test "saving written requirements creates no shared catalog entries" do
    assert_no_difference [ "Skill.count", "Equipment.count" ] do
      post usr_company_jobs_path(@company), params: { job: valid_job_attributes.merge(
        required_occupation_ids: [ @occupation.id ], required_skills_text: "Tour advancing", preferred_equipment_text: "Custom lighting console"
      ) }
    end
    assert_response :redirect
    job = Job.order(:id).last
    assert_equal "Tour advancing", job.required_skills_text
    assert_equal "Custom lighting console", job.preferred_equipment_text
    assert_equal [ @occupation ], job.required_occupations
  end

  test "job form exposes structured taxonomy controls" do
    get new_usr_company_job_path(@company)

    assert_response :success
    assert_select ".job-description-editor"
    assert_select "p.form-label", text: "Description"
    assert_select "*", text: /uploads coming soon/i, count: 0
    assert_select "[data-controller='taxonomy-multiselect']", count: 1
    assert_select "input[type='search'][role='combobox']", count: 1
    assert_select "select[name='job[required_occupation_ids][]'][multiple]", hidden: true
  end

  test "job form preserves occupation and personal entries after validation errors" do
    post usr_company_jobs_path(@company), params: { job: valid_job_attributes.merge(
      title: "", required_occupation_ids: [ @occupation.id ], preferred_equipment_text: "My custom console"
    ) }
    assert_response :unprocessable_entity
    assert_select "#job_required_occupation_ids_combobox [data-taxonomy-multiselect-target='chip'][data-taxonomy-value='#{@occupation.id}']"
    assert_select "textarea[name='job[preferred_equipment_text]']", text: "My custom console"
  end

  test "completing a job creates verified work history for assigned crew" do
    completion_attributes = valid_job_attributes.merge(
      posting_type: "multi_position",
      starts_at: 2.days.ago,
      ends_at: 1.day.ago
    )
    job = @company.jobs.create!(completion_attributes)
    position = job.crew_positions.create!(title: "A1", headcount: 1)
    position.crew_assignments.create!(profile: @owner.user_profile)

    assert_difference -> { @owner.user_profile.credits.count }, 1 do
      patch usr_company_job_path(@company, job), params: {
        job: completion_attributes.merge(status: "completed")
      }
    end

    assert_redirected_to usr_company_path(@company)
    assert job.reload.completed?
    assert job.completed_at.present?
    assert @owner.user_profile.credits.last.verified?
  end

  private

  def valid_job_attributes
    {
      title: "Arena Audio",
      workplace_type: "on_site",
      employment_type: "contract",
      posting_type: "single_role",
      status: "published",
      is_active: true,
      description: "Mix arena audio."
    }
  end
end
