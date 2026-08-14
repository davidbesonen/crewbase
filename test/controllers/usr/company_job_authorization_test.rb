require "test_helper"

class Usr::CompanyJobAuthorizationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = create_user("owner")
    @outsider = create_user("outsider")
    @industry = Industry.create!(name: "Authorization")
    @company = Company.create!(
      name: "Owner Company",
      contact_email: "owner-company@example.com",
      industries: [ @industry ],
      is_public: true
    )
    @company.company_assignments.create!(user: @owner, role: "owner")
    @team_plan = Plan.create!(name: "Team", key: "team", monthly_price_cents: 4_900, annual_price_cents: 49_000, active: true, position: 2)
    @company.company_plans.create!(plan: @team_plan)
    @job = @company.jobs.create!(
      title: "Stage Manager",
      workplace_type: :on_site,
      employment_type: :contract,
      status: :draft,
      is_active: false,
      description: "Manage the stage."
    )
  end

  test "non-owner cannot edit update or destroy a company" do
    sign_in @outsider, scope: :user

    get edit_usr_company_path(@company)
    assert_response :not_found

    sign_in @outsider, scope: :user
    patch usr_company_path(@company), params: {
      company: { name: "Stolen Company", contact_email: "stolen@example.com", industry_ids: [ @industry.id ] }
    }
    assert_response :not_found
    assert_equal "Owner Company", @company.reload.name

    sign_in @outsider, scope: :user
    assert_no_difference("Company.count") do
      delete usr_company_path(@company)
    end
    assert_response :not_found
  end

  test "non-owner cannot access or mutate company job management" do
    sign_in @outsider, scope: :user

    get usr_company_jobs_path(@company)
    assert_response :not_found

    sign_in @outsider, scope: :user
    get new_usr_company_job_path(@company)
    assert_response :not_found

    sign_in @outsider, scope: :user
    assert_no_difference("Job.count") do
      post usr_company_jobs_path(@company), params: {
        job: valid_job_attributes(title: "Unauthorized Job")
      }
    end
    assert_response :not_found

    sign_in @outsider, scope: :user
    get edit_usr_company_job_path(@company, @job)
    assert_response :not_found

    sign_in @outsider, scope: :user
    patch usr_company_job_path(@company, @job), params: {
      job: valid_job_attributes(title: "Stolen Job")
    }
    assert_response :not_found
    assert_equal "Stage Manager", @job.reload.title

    sign_in @outsider, scope: :user
    assert_no_difference("Job.count") do
      delete usr_company_job_path(@company, @job)
    end
    assert_response :not_found
  end

  test "draft and inactive jobs are hidden from non-owners and cannot receive applications" do
    sign_in @outsider, scope: :user

    get usr_job_path(@job)
    assert_response :not_found

    sign_in @outsider, scope: :user
    get new_usr_job_job_application_path(@job)
    assert_response :not_found

    sign_in @outsider, scope: :user
    assert_no_difference("JobApplication.count") do
      post usr_job_job_applications_path(@job), params: {
        job_application: { additional_information: "Please consider me." }
      }
    end
    assert_response :not_found
  end

  test "company selector only lists companies the user owns" do
    employee_company = Company.create!(
      name: "Employer Company",
      contact_email: "employer@example.com",
      industries: [ @industry ]
    )
    employee_company.company_assignments.create!(user: @owner, role: "employee")
    sign_in @owner, scope: :user

    get select_company_usr_jobs_path

    assert_response :success
    assert_select "a", text: @company.name
    assert_select "a", text: employee_company.name, count: 0
  end

  test "owner can view the company jobs management index" do
    sign_in @owner, scope: :user

    get usr_company_jobs_path(@company)

    assert_response :success
    assert_select "h1", text: "Jobs for #{@company.name}"
    assert_select "a[href='#{edit_usr_company_job_path(@company, @job)}']", text: "Edit"
  end

  test "private companies are only visible to assigned users" do
    private_company = Company.create!(
      name: "Private Company",
      contact_email: "private@example.com",
      industries: [ @industry ],
      is_public: false
    )
    private_company.company_assignments.create!(user: @owner, role: "employee")
    sign_in @outsider, scope: :user

    get usr_companies_path
    assert_response :success
    assert_select "a", text: private_company.name, count: 0

    get search_usr_companies_path, params: { q: "Private Company" }, as: :json
    assert_response :success
    assert_empty JSON.parse(response.body)

    get usr_company_path(private_company)
    assert_response :not_found

    sign_in @owner, scope: :user
    get usr_company_path(private_company)
    assert_response :success
  end

  test "owner job management pages support valid and invalid create update and destroy flows" do
    sign_in @owner, scope: :user

    get new_usr_company_job_path(@company)
    assert_response :success

    assert_no_difference("Job.count") do
      post usr_company_jobs_path(@company), params: {
        job: valid_job_attributes(title: "")
      }
    end
    assert_response :unprocessable_entity

    assert_difference("Job.count", 1) do
      post usr_company_jobs_path(@company), params: {
        job: valid_job_attributes(title: "Tour Manager")
      }
    end
    created_job = Job.order(:id).last
    assert_redirected_to usr_company_path(@company)

    get edit_usr_company_job_path(@company, created_job)
    assert_response :success

    patch usr_company_job_path(@company, created_job), params: {
      job: valid_job_attributes(title: "")
    }
    assert_response :unprocessable_entity
    assert_equal "Tour Manager", created_job.reload.title

    patch usr_company_job_path(@company, created_job), params: {
      job: valid_job_attributes(title: "Updated Tour Manager")
    }
    assert_redirected_to usr_company_path(@company)
    assert_equal "Updated Tour Manager", created_job.reload.title

    assert_difference("Job.count", -1) do
      delete usr_company_job_path(@company, created_job)
    end
    assert_redirected_to usr_company_jobs_path(@company)
  end

  test "company cannot publish jobs beyond its active job capacity" do
    assign_plan(active_jobs_limit: 1)
    @job.update!(status: :published, is_active: true, published_at: Time.current)
    sign_in @owner, scope: :user

    assert_no_difference "Job.count" do
      post usr_company_jobs_path(@company), params: {
        job: valid_job_attributes(title: "Over Capacity").merge(status: "published", is_active: "1")
      }
    end

    assert_response :unprocessable_entity
    assert_select "[data-plan-limit-message]", text: /Starter plan allows 1 active job/i
  end

  test "company at its active job capacity can still save a draft" do
    assign_plan(active_jobs_limit: 1)
    @job.update!(status: :published, is_active: true, published_at: Time.current)
    sign_in @owner, scope: :user

    assert_difference "Job.count", 1 do
      post usr_company_jobs_path(@company), params: {
        job: valid_job_attributes(title: "Future Draft")
      }
    end
  end

  test "new job form starts with a clear required posting type choice" do
    sign_in @owner, scope: :user

    get new_usr_company_job_path(@company)

    assert_response :success
    assert_select "fieldset[data-posting-type-choice]" do
      assert_select "legend", text: "What are you posting?"
      assert_select "input[type='radio'][name='job[posting_type]'][value='single_role'][required]"
      assert_select "label", text: /Single job posting/
      assert_select "*", text: /one person for one role/
      assert_select "input[type='radio'][name='job[posting_type]'][value='multi_position'][required]"
      assert_select "label", text: /Multi-position gig/
      assert_select "*", text: /several roles and headcounts/
    end
    assert_select "[data-gig-positions]" do
      assert_select "input[name='job[crew_positions_attributes][0][title]'][required]"
      assert_select "input[name='job[crew_positions_attributes][0][headcount]'][required]"
    end
    posting_choice_position = response.body.index("data-posting-type-choice")
    title_position = response.body.index("job_title")
    assert_operator posting_choice_position, :<, title_position
  end

  test "starter companies see multi-position gigs locked and cannot submit one directly" do
    @company.company_plans.delete_all
    starter = Plan.create!(name: "Starter", key: "starter", monthly_price_cents: 1_900, annual_price_cents: 19_000, active: true, position: 1)
    @company.company_plans.create!(plan: starter)
    sign_in @owner, scope: :user

    get new_usr_company_job_path(@company)

    assert_response :success
    assert_select "input[name='job[posting_type]'][value='multi_position'][disabled]"
    assert_select "[data-feature-upgrade='multi-position-gigs']", text: /Team and Studio plans/i

    assert_no_difference("Job.count") do
      post usr_company_jobs_path(@company), params: {
        job: valid_job_attributes(title: "Locked Festival").merge(
          posting_type: "multi_position",
          crew_positions_attributes: { "0" => { title: "Audio Engineer", headcount: 1 } }
        )
      }
    end
    assert_redirected_to usr_company_path(@company)
    assert_match(/requires a Team or Studio plan/, flash[:alert])
  end

  test "owner creates a multi-position gig and sees its staffing workspace" do
    sign_in @owner, scope: :user

    assert_difference("Job.count", 1) do
      assert_difference("CrewPosition.count", 1) do
        post usr_company_jobs_path(@company), params: {
          job: valid_job_attributes(title: "Festival Production").merge(
            posting_type: "multi_position",
            crew_positions_attributes: {
              "0" => { title: "Stage Manager", headcount: 2 }
            }
          )
        }
      end
    end

    job = Job.order(:id).last
    assert job.multi_position?
    assert_equal [ [ "Stage Manager", 2 ] ], job.crew_positions.pluck(:title, :headcount)

    get usr_job_path(job)
    assert_select "a[href='#{usr_job_crew_path(job)}']", text: "Staff This Gig"
  end

  test "owner cannot create a multi-position gig without a crew position" do
    sign_in @owner, scope: :user

    assert_no_difference([ "Job.count", "CrewPosition.count" ]) do
      post usr_company_jobs_path(@company), params: {
        job: valid_job_attributes(title: "Festival Production").merge(posting_type: "multi_position")
      }
    end

    assert_response :unprocessable_entity
    assert_select ".text-danger", text: /include at least one position/
  end

  test "single-role posting does not expose the staffing workspace" do
    @job.update!(posting_type: :single_role, status: :published, is_active: true, published_at: Time.current)
    @outsider.user_profile.experiences.create!(
      title: "Stage Manager",
      company_name: "Touring Company",
      start_year: Date.current.year - 2,
      end_year: Date.current.year
    )
    sign_in @owner, scope: :user

    get usr_job_path(@job)
    assert_response :success
    assert_select "[data-job-crew-recommendation]", count: 1
    assert_select "a[href='#{usr_job_crew_path(@job)}']", count: 0
    assert_select "a[href='#{usr_profiles_path(recommended: "1")}']", text: "View All"

    get usr_job_crew_path(@job)
    assert_response :not_found

    assert_no_difference("CrewPosition.count") do
      post usr_job_crew_positions_path(@job), params: {
        crew_position: { title: "Audio Engineer", headcount: 1 }
      }
    end
    assert_response :not_found
  end

  test "owner can create and edit a job with selected work dates" do
    sign_in @owner, scope: :user

    get new_usr_company_job_path(@company)
    assert_response :success
    assert_select "input[name='job[work_dates][]']"

    assert_difference("Job.count", 1) do
      post usr_company_jobs_path(@company), params: {
        job: valid_job_attributes(title: "Tour Crew").merge(
          starts_at: "2026-09-01T09:00",
          ends_at: "2026-12-31T18:00",
          work_dates: [ "2026-09-05", "", "2026-11-14" ]
        )
      }
    end

    job = Job.order(:id).last
    assert_equal [ Date.new(2026, 9, 5), Date.new(2026, 11, 14) ], job.work_dates

    get edit_usr_company_job_path(@company, job)
    assert_response :success
    assert_select "input[name='job[work_dates][]'][value='2026-09-05']"
    assert_select "input[name='job[work_dates][]'][value='2026-11-14']"

    get usr_job_path(job)
    assert_response :success
    assert_select "[data-job-work-dates]", text: /September 05, 2026/
    assert_select "[data-job-work-dates]", text: /November 14, 2026/

    patch usr_company_job_path(@company, job), params: {
      job: valid_job_attributes(title: "Tour Crew").merge(
        starts_at: "2026-09-01T09:00",
        ends_at: "2026-12-31T18:00",
        work_dates: [ "2026-10-10" ]
      )
    }

    assert_equal [ Date.new(2026, 10, 10) ], job.reload.work_dates
  end

  test "published job discovery and application pages render and submit" do
    internal_project = @company.projects.create!(name: "Confidential Client Launch")
    @job.update!(project: internal_project)
    @job.update!(status: :published, is_active: true, published_at: Time.current)
    sign_in @outsider, scope: :user

    get usr_jobs_path
    assert_response :success
    assert_select "a[href='#{usr_job_path(@job)}']", text: @job.title
    assert_select ".card-accent.card-accent-sky", minimum: 1

    get usr_job_path(@job)
    assert_response :success
    assert_select ".app-hero.app-hero-sky", count: 1
    assert_select ".card-accent.card-accent-cyan", minimum: 1
    assert_select ".status-badge.status-open", text: "Published"
    assert_not_includes response.body, internal_project.name
    assert_select "a[href='#{usr_project_path(internal_project)}']", count: 0

    get new_usr_job_job_application_path(@job)
    assert_response :success
    assert_not_includes response.body, internal_project.name

    assert_difference("JobApplication.count", 1) do
      post usr_job_job_applications_path(@job), params: {
        job_application: {
          additional_information: "<div>Experienced applicant</div>",
          question_answers: {}
        }
      }
    end
    application = JobApplication.order(:id).last
    assert_redirected_to usr_job_path(@job)

    get usr_job_applications_path
    assert_response :success
    assert_select "a[href='#{usr_job_application_path(application)}']", text: @job.title

    get usr_job_application_path(application)
    assert_response :success

    get new_usr_job_job_application_path(@job)
    assert_redirected_to usr_job_application_path(application)
  end

  test "owner sees recommended crew on their job while other users do not" do
    @job.update!(
      title: "Lighting Technician",
      description: "Operate Lighting equipment.",
      status: :published,
      is_active: true,
      published_at: Time.current
    )
    candidate = create_user("candidate")
    candidate.user_profile.experiences.create!(
      title: "Lighting Technician",
      company_name: "Touring Co",
      start_year: Date.current.year - 5,
      end_year: Date.current.year
    )

    sign_in @owner, scope: :user
    get usr_job_path(@job)

    assert_response :success
    assert_select "[data-job-crew-recommendation]", text: /Candidate User/
    assert_select "[data-job-crew-recommendation]", text: /5 years relevant experience/

    sign_in @outsider, scope: :user
    get usr_job_path(@job)

    assert_response :success
    assert_select "[data-job-crew-recommendation]", count: 0
  end

  test "job owner can open the job staffing workspace" do
    @job.update!(posting_type: :multi_position)
    sign_in @owner, scope: :user

    get usr_job_path(@job)

    assert_response :success
    assert_select "[data-job-primary-actions]" do
      assert_select "a[href='#{usr_job_crew_path(@job)}']", text: "Staff This Gig"
      assert_select "form[action='#{usr_job_saved_job_path(@job)}']"
    end
    assert_select "[data-job-heading-controls] a[href='#{usr_job_crew_path(@job)}']", count: 0
  end

  test "job owner is not invited to apply to their own posting" do
    @job.update!(status: :published, is_active: true)
    sign_in @owner, scope: :user

    get usr_job_path(@job)

    assert_response :success
    assert_select "a[href='#{new_usr_job_job_application_path(@job)}']", count: 0
    assert_select "a", text: /\AApply\z/, count: 0
  end

  test "application counts link owners to the job-filtered pipeline but remain plain text for other users" do
    @job.update!(status: :published, is_active: true, published_at: Time.current)
    @job.job_applications.create!(profile: @outsider.user_profile, status: :submitted)
    applications_path = usr_company_applications_path(@company, job_id: @job.id)

    sign_in @owner, scope: :user
    get usr_job_path(@job)

    assert_response :success
    assert_select "a[href='#{applications_path}']", text: "1 application", count: 2

    sign_in @outsider, scope: :user
    get usr_job_path(@job)

    assert_response :success
    assert_select "a[href='#{applications_path}']", count: 0
    assert_select ".badge", text: "1 application"
  end

  private

  def create_user(label)
    user = User.create!(
      first_name: label.titleize,
      last_name: "User",
      email: "#{label}-authorization@example.com",
      password: "password123"
    )
    user.profiles.create!(profile_type: "user", completed_at: Time.current)
    user.visits.create!
    user
  end

  def valid_job_attributes(title:)
    {
      title: title,
      workplace_type: "on_site",
      employment_type: "contract",
      posting_type: "single_role",
      status: "draft",
      description: "Job description"
    }
  end

  def assign_plan(active_jobs_limit:)
    plan = Plan.create!(
      key: "starter",
      name: "Starter",
      monthly_price_cents: 1_900,
      annual_price_cents: 19_000,
      data: { "active_jobs_limit" => active_jobs_limit }
    )
    @company.company_plans.create!(plan:)
  end
end
