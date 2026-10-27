require "test_helper"

class Usr::StaffingStartsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Staff", last_name: "Owner", email: "staff-start@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Staffing Start Co", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @plan = Plan.create!(name: "Staffing Team", key: "team", monthly_price_cents: 1900, annual_price_cents: 19000, data: { "projects_limit" => 5, "active_jobs_limit" => 10 })
    @company.company_plans.create!(plan: @plan)
    sign_in @owner
  end

  test "owners choose the show structure before defining roles without creating records" do
    assert_no_difference [ "Project.count", "Job.count" ] do
      get "/usr/staff-a-gig"
    end
    assert_response :success
    assert_select "h1", text: "Staff a Gig"
    assert_select "input[name='staffing[kind]']", count: 2
    assert_select "input[name='staffing[company_id]'][value='#{@company.id}']"
    assert_select "button", text: "Continue"
    assert_select "[data-staffing-start]", text: /single gig can still need several roles/
  end

  test "a single gig continues to roles while a tour starts with a project" do
    assert_no_difference [ "Project.count", "Job.count" ] do
      post "/usr/staff-a-gig", params: { staffing: { company_id: @company.id, kind: "single" } }
    end
    assert_redirected_to new_usr_company_job_path(@company, staffing_kind: "single", audience: "invite_only")
    follow_redirect!
    assert_select "input[name='job[posting_type]'][value='multi_position'][checked]"
    assert_select "select[name='job[audience]'] option[value='invite_only'][selected]"
    post "/usr/staff-a-gig", params: { staffing: { company_id: @company.id, kind: "multi_show" } }
    assert_redirected_to new_usr_company_project_path(@company)
  end

  test "the first show automatically creates its project and opens the run workspace" do
    assert_difference [ "Project.count", "Job.count" ], 1 do
      post usr_company_jobs_path(@company), params: submission("multi_show")
    end
    job = @company.jobs.last
    assert_equal "Summer Festival", job.project.name
    assert job.project.multi_show?
    assert_equal @company.id, job.project.company_id
    assert_equal Date.new(2030, 6, 1), job.project.starts_on
    assert_nil job.project.ends_on
    assert job.invite_only?
    assert job.published?
    assert_equal 2, job.crew_positions.first.headcount
    assert_redirected_to usr_project_path(job.project)
    follow_redirect!
    get usr_project_path(job.project, view: "roles")
    assert_select "h2", text: "Roles & Postings"
    assert_select "a[href='#{new_usr_company_job_path(@company, project_id: job.project_id, audience: 'invite_only')}']", text: "Post A Job"
    assert_select "a[href='#{usr_job_crew_path(job)}']", text: "Staff Crew"
    assert_select ".app-hero a.btn-primary[href='#{usr_project_path(job.project, view: "crew")}']", text: "Plan Crew"
    assert_select "h2", text: "Overview", count: 0
  end

  test "a single gig goes directly to staffing without creating a project" do
    assert_no_difference "Project.count" do
      assert_difference "Job.count", 1 do
        post usr_company_jobs_path(@company), params: submission("single")
      end
    end
    job = @company.jobs.last
    assert_nil job.project_id
    assert_redirected_to usr_job_crew_path(job)
  end

  test "a gig needing one person opens roster planning without creating extra roles" do
    values = submission("single")
    values[:job][:posting_type] = "single_role"
    values[:job].delete(:crew_positions_attributes)
    assert_no_difference [ "Project.count", "CrewPosition.count" ] do
      post usr_company_jobs_path(@company), params: values
    end
    assert_redirected_to usr_company_staffing_path(@company, from: "2030-06-01")
    assert @company.jobs.last.single_role?
    follow_redirect!
    assert_select "a[href='#{usr_profiles_path(recommended: '1')}']", text: "Find Crew"
  end

  test "the first gig can book a crew for the full run and recruit publicly when requested" do
    values = submission("multi_show")
    values[:job].merge!(title: "Tour-Wide Crew", ends_at: "2030-06-30", audience: "public_listing")
    post usr_company_jobs_path(@company), params: values
    job = @company.jobs.find_by!(title: "Tour-Wide Crew")
    assert job.project.multi_show?
    assert job.public_listing?
    assert_equal Date.new(2030, 6, 30), job.ends_at.to_date
    assert_redirected_to usr_project_path(job.project)
  end

  test "invalid first shows and blank run names keep the form and create no empty project" do
    values = submission("multi_show")
    values[:job][:title] = ""
    assert_no_difference [ "Project.count", "Job.count" ] do
      post usr_company_jobs_path(@company), params: values
    end
    assert_response :unprocessable_entity
    assert_select "input[name='staffing_project_name'][value='Summer Festival']"
    assert_select "input[name='staffing_kind'][value='multi_show']"
    assert_select "input[name='job[crew_positions_attributes][0][title]'][value='Stage Tech']"

    values = submission("multi_show").merge(staffing_project_name: " ")
    assert_no_difference [ "Project.count", "Job.count" ] do
      post usr_company_jobs_path(@company), params: values
    end
    assert_response :unprocessable_entity
    assert_select ".alert", text: /tour or event name/
  end

  test "automatic projects respect the same company plan capacity as manual projects" do
    @plan.update!(data: @plan.data.merge("projects_limit" => 0))
    assert_no_difference [ "Project.count", "Job.count" ] do
      post usr_company_jobs_path(@company), params: submission("multi_show")
    end
    assert_response :unprocessable_entity
    assert_select ".alert", text: /0 active projects/
    assert_select "input[name='staffing_project_name'][value='Summer Festival']"
  end

  test "company selection only lists owned companies and rejects a foreign company" do
    other = Company.create!(name: "Not Mine", contact_email: "not-mine@example.com", industries: @company.industries)
    second = Company.create!(name: "Second Owned", contact_email: "second-staff@example.com", industries: @company.industries)
    second.company_assignments.create!(user: @owner, role: "owner")
    get "/usr/staff-a-gig"
    assert_select "select[name='staffing[company_id]'] option[value='#{second.id}']"
    assert_select "option[value='#{other.id}']", count: 0
    post "/usr/staff-a-gig", params: { staffing: { company_id: other.id, kind: "single" } }
    assert_response :not_found
  end

  test "owners with multiple companies must choose a company before continuing" do
    second = Company.create!(name: "Second Owned", contact_email: "second-staff@example.com", industries: @company.industries)
    second.company_assignments.create!(user: @owner, role: "owner")

    get "/usr/staff-a-gig"
    assert_select "select[name='staffing[company_id]'][required]" do
      assert_select "option[value='']", text: "Choose your company"
      assert_select "option[selected]", count: 0
    end

    assert_no_difference [ "Project.count", "Job.count" ] do
      post "/usr/staff-a-gig", params: { staffing: { company_id: "", kind: "single" } }
    end
    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Choose a company/
    assert_select "input[name='staffing[kind]'][value='single'][checked]"
  end

  test "the chosen company owns the gig and its automatically created project" do
    second = Company.create!(name: "Second Owned", contact_email: "second-staff@example.com", industries: @company.industries)
    second.company_assignments.create!(user: @owner, role: "owner")
    second.company_plans.create!(plan: @plan)

    post "/usr/staff-a-gig", params: { staffing: { company_id: second.id, kind: "multi_show" } }
    assert_redirected_to new_usr_company_project_path(second)
    follow_redirect!
    assert_select "form[action='#{usr_company_projects_path(second)}']"

    assert_no_difference [ "@company.jobs.count", "@company.projects.count" ] do
      assert_difference [ "second.jobs.count", "second.projects.count" ], 1 do
        post usr_company_jobs_path(second), params: submission("multi_show")
      end
    end
    job = second.jobs.last
    assert_equal second.id, job.project.company_id
    assert_redirected_to usr_project_path(job.project)
  end

  test "invalid choices are recoverable and unauthenticated visitors must sign in" do
    post "/usr/staff-a-gig", params: { staffing: { company_id: @company.id, kind: "invalid" } }
    assert_response :unprocessable_entity
    assert_select "[role='alert']"
    sign_out @owner
    get "/usr/staff-a-gig"
    assert_redirected_to new_user_session_path
  end

  test "legacy starter companies can group a tour while retaining their one-person staffing limit" do
    @plan.update!(key: "starter")
    get new_usr_company_job_path(@company, staffing_kind: "multi_show")
    assert_response :success
    assert_select "input[name='job[posting_type]'][value='single_role'][checked]"
    assert_select "input[name='job[posting_type]'][value='multi_position'][disabled]"
    assert_select "input[name='staffing_project_name']"
  end

  test "a company is required before starting a staffing flow" do
    @company.company_assignments.destroy_all
    get "/usr/staff-a-gig"
    assert_redirected_to new_usr_company_path
  end

  private

  def submission(kind)
    { staffing_kind: kind, staffing_project_name: "Summer Festival", publication_action: "publish", job: {
      title: "Opening Night", description: "Set up the main stage", audience: "invite_only", posting_type: "multi_position",
      employment_type: "contract", workplace_type: "on_site", starts_at: "2030-06-01", ends_at: "2030-06-02",
      crew_positions_attributes: { "0" => { title: "Stage Tech", headcount: 2 } }
    } }
  end
end
