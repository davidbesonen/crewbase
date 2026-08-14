require "test_helper"

class Usr::ProjectsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  setup do
    @owner = User.create!(
      first_name: "Parker",
      last_name: "Owner",
      email: "project-owner@example.com",
      password: "password123"
    )
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    industry = Industry.create!(name: "Project Production")
    @company = Company.create!(
      name: "Project Company",
      contact_email: "project-company@example.com",
      industries: [ industry ]
    )
    @company.company_assignments.create!(user: @owner, role: "owner")
    team = Plan.create!(name: "Team", key: "team", monthly_price_cents: 4_900, annual_price_cents: 49_000, active: true, position: 2)
    @company.company_plans.create!(plan: team)
  end

  test "company owner creates and manages a lightweight project" do
    sign_in @owner, scope: :user

    assert_difference "Project.count", 1 do
      post usr_company_projects_path(@company), params: {
        project: {
          name: "Festival Weekend",
          description: "Staff the main and second stages.",
          status: "active",
          starts_on: "2026-08-14",
          ends_on: "2026-08-16"
        }
      }
    end

    project = Project.order(:id).last
    assert_redirected_to usr_project_path(project)

    get usr_project_path(project)
    assert_response :success
    assert_select "h1", text: "Festival Weekend"
    assert_select "[data-project-jobs]", text: /No job postings/

    patch usr_project_path(project), params: {
      project: { name: "Festival Weekend Updated", status: "completed" }
    }
    assert_redirected_to usr_project_path(project)
    assert_equal "Festival Weekend Updated", project.reload.name
    assert project.completed?
  end

  test "Starter company cannot create projects beyond its active project limit" do
    assign_plan(key: "starter", projects_limit: 2)
    2.times { |index| @company.projects.create!(name: "Active Project #{index}") }
    sign_in @owner, scope: :user

    assert_no_difference "Project.count" do
      post usr_company_projects_path(@company), params: {
        project: { name: "Over the limit", status: "planning" }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[data-plan-limit-message]", text: /Starter plan allows 2 active projects/i
  end

  test "archived projects do not consume the active project limit" do
    assign_plan(key: "starter", projects_limit: 2)
    @company.projects.create!(name: "Current Project")
    @company.projects.create!(name: "Archived Project", archived_at: 1.day.ago)
    sign_in @owner, scope: :user

    assert_difference "Project.count", 1 do
      post usr_company_projects_path(@company), params: {
        project: { name: "Replacement Project", status: "planning" }
      }
    end

    assert_redirected_to usr_project_path(Project.order(:id).last)
  end

  test "edit project form submits to the standalone project update route" do
    project = @company.projects.create!(name: "Editable Project")
    sign_in @owner, scope: :user

    get edit_usr_project_path(project)

    assert_response :success
    assert_select "form[action='#{usr_project_path(project)}'][method='post']" do
      assert_select "input[name='_method'][value='patch']"
    end
  end

  test "project index uses a calm header, accented cards, and semantic statuses" do
    @company.projects.create!(name: "Indexed Project", status: :completed)
    sign_in @owner, scope: :user

    get usr_company_projects_path(@company)

    assert_response :success
    assert_select ".app-hero.app-hero-cyan", text: /Projects/
    assert_select ".card-accent.card-accent-cyan", text: /Indexed Project/
    assert_select ".status-badge.status-completed", text: "Completed"
  end

  test "non-owner cannot access or mutate a company project" do
    project = @company.projects.create!(name: "Private Project")
    outsider = User.create!(
      first_name: "Other",
      last_name: "User",
      email: "project-outsider@example.com",
      password: "password123"
    )
    outsider.profiles.create!(profile_type: "user", completed_at: Time.current)
    sign_in outsider, scope: :user

    get usr_project_path(project)
    assert_response :not_found

    sign_in outsider, scope: :user
    assert_no_difference "Project.count" do
      post usr_company_projects_path(@company), params: {
        project: { name: "Unauthorized" }
      }
    end
    assert_response :not_found
  end

  test "owner can archive and restore a project" do
    project = @company.projects.create!(name: "Seasonal Tour")
    sign_in @owner, scope: :user

    patch "/usr/projects/#{project.id}/archive"

    assert_redirected_to usr_company_projects_path(@company)
    assert project.reload.archived?
    sign_in @owner, scope: :user
    patch "/usr/projects/#{project.id}/restore"

    assert_redirected_to usr_project_path(project)
    assert_not project.reload.archived?
  end

  test "project index separates archived projects from current projects" do
    current_project = @company.projects.create!(name: "Current Festival")
    archived_project = @company.projects.create!(name: "Archived Festival", archived_at: 1.day.ago)
    sign_in @owner, scope: :user

    get usr_company_projects_path(@company)

    assert_response :success
    assert_select "[data-active-projects]" do
      assert_select "a[href='#{usr_project_path(current_project)}']", text: current_project.name
      assert_select "*", text: /#{archived_project.name}/, count: 0
    end
    assert_select "[data-archived-projects]" do
      assert_select "a[href='#{usr_project_path(archived_project)}']", text: archived_project.name
      assert_select "form[action='/usr/projects/#{archived_project.id}/restore']"
    end
  end

  test "non-owner cannot archive or restore projects" do
    project = @company.projects.create!(name: "Owner Only Archive")
    outsider = User.create!(
      first_name: "Archive",
      last_name: "Outsider",
      email: "archive-outsider@example.com",
      password: "password123"
    )
    outsider.profiles.create!(profile_type: "user", completed_at: Time.current)
    sign_in outsider, scope: :user

    patch "/usr/projects/#{project.id}/archive"
    assert_response :not_found
    assert_not project.reload.archived?

    project.archive!
    sign_in outsider, scope: :user
    patch "/usr/projects/#{project.id}/restore"
    assert_response :not_found
    assert project.reload.archived?
  end

  test "project names remain hidden on public company job listings" do
    project = @company.projects.create!(name: "Confidential Production")
    job = create_project_job(project:, title: "Public Music Producer", status: :published)
    outsider = User.create!(
      first_name: "Job",
      last_name: "Seeker",
      email: "project-visibility@example.com",
      password: "password123"
    )
    outsider.profiles.create!(profile_type: "user", completed_at: Time.current)
    sign_in outsider, scope: :user

    get usr_company_path(@company)

    assert_response :success
    assert_select "a[href='#{usr_job_path(job)}']", text: job.title
    assert_select "*", text: /#{project.name}/, count: 0
    assert_select "a[href='#{usr_project_path(project)}']", count: 0
  end

  test "archived projects cannot receive new job postings" do
    project = @company.projects.create!(name: "Archived Staffing Plan", archived_at: 1.day.ago)
    sign_in @owner, scope: :user

    get new_usr_company_job_path(@company, project_id: project.id)
    assert_response :not_found

    sign_in @owner, scope: :user
    assert_no_difference "Job.count" do
      post usr_company_jobs_path(@company), params: {
        job: {
          title: "Archived Project Role",
          description: "This role must not be attached to an archived project.",
          employment_type: "contract",
          workplace_type: "on_site",
          status: "draft",
          is_active: true,
          project_id: project.id
        }
      }
    end
    assert_response :not_found
  end

  test "project dashboard summarizes postings and provides direct management actions" do
    project = @company.projects.create!(
      name: "Festival Dashboard",
      description: "Coordinate staffing across festival stages.",
      status: :active,
      starts_on: Date.new(2026, 8, 14),
      ends_on: Date.new(2026, 8, 16)
    )
    published_job = create_project_job(project:, title: "Lighting Designer", status: :published)
    draft_job = create_project_job(project:, title: "Stage Manager", status: :draft)
    2.times { |index| create_application(job: published_job, index:) }
    create_application(job: draft_job, index: 2)
    sign_in @owner, scope: :user

    get usr_project_path(project)

    assert_response :success
    assert_select "[data-project-dashboard]" do
      assert_select "h1", text: project.name
      assert_select "[data-project-metric='postings']", text: /2/
      assert_select "[data-project-metric='open-postings']", text: /1/
      assert_select "[data-project-metric='applications'] a[href='#{usr_company_applications_path(@company, project_id: project.id)}'].text-decoration-none", text: "3"
      assert_select "a[href='#{new_usr_company_job_path(@company, project_id: project.id)}']", text: "Add Job Posting", count: 1
      assert_select "form[action='/usr/projects/#{project.id}/archive'] button", text: "Archive Project"
      assert_select "[data-project-job='#{published_job.id}']" do
        assert_select "a[href='#{usr_company_applications_path(@company, job_id: published_job.id)}']", text: "2 applicants"
        assert_select "a[href='#{usr_job_path(published_job)}']", text: "View Posting"
        assert_select "a[href='#{edit_usr_company_job_path(@company, published_job)}']", text: "Edit"
        assert_select "a[href='#{usr_company_applications_path(@company, job_id: published_job.id)}']", text: "Review Applicants"
      end
    end
  end

  test "project screens use meaningful status and restrained operational accents" do
    project = @company.projects.create!(name: "Color Coded Project", status: :active)
    create_project_job(project:, title: "Open Role", status: :published)
    sign_in @owner, scope: :user

    get usr_project_path(project)

    assert_response :success
    assert_select "[data-project-dashboard] .app-hero.app-hero-cyan"
    assert_select "[data-project-dashboard] .status-badge.status-open", text: "Active"
    assert_select "[data-project-metric].card-accent", count: 3
    assert_select "[data-project-jobs].card-accent.card-accent-sky"
    assert_select "[data-project-job] .status-badge.status-open", text: "Published"
  end

  test "empty project dashboard explains the next step" do
    project = @company.projects.create!(name: "New Production")
    sign_in @owner, scope: :user

    get usr_project_path(project)

    assert_response :success
    assert_select "[data-project-empty-state].empty-state.empty-state-sky", text: /Create the first job posting/
    assert_select "[data-project-empty-state] a[href='#{new_usr_company_job_path(@company, project_id: project.id)}']", text: "Add Job Posting"
  end

  test "dashboard offers project creation only to company owners" do
    sign_in @owner, scope: :user

    get usr_dashboards_path

    assert_response :success
    assert_select "a", text: "Create a Project"
    assert_select "a[href='#{new_usr_company_project_path(@company)}']", text: "Create a Project"
  end

  private

  def assign_plan(key:, projects_limit:)
    plan = Plan.create!(
      key:,
      name: key.titleize,
      monthly_price_cents: 1_900,
      annual_price_cents: 19_000,
      data: { "projects_limit" => projects_limit }
    )
    @company.company_plans.create!(plan:)
  end

  def create_project_job(project:, title:, status:)
    project.company.jobs.create!(
      project:,
      title:,
      description: "Project dashboard role.",
      employment_type: :contract,
      workplace_type: :on_site,
      status:,
      is_active: true,
      published_at: (Time.current if status == :published)
    )
  end

  def create_application(job:, index:)
    applicant = User.create!(
      first_name: "Applicant#{index}",
      last_name: "Person",
      email: "project-dashboard-applicant-#{index}@example.com",
      password: "password123"
    )
    profile = applicant.profiles.create!(profile_type: "user", completed_at: Time.current)
    profile.job_applications.create!(job:, status: :submitted)
  end
end
