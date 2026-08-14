require "test_helper"

class Usr::ProjectJobsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  self.fixture_table_names = []

  test "owner can create a job already assigned to a project" do
    owner = User.create!(
      first_name: "Jordan",
      last_name: "Producer",
      email: "project-job-owner@example.com",
      password: "password123"
    )
    owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    industry = Industry.create!(name: "Project Jobs")
    company = Company.create!(
      name: "Project Jobs Company",
      contact_email: "project-jobs@example.com",
      industries: [ industry ]
    )
    company.company_assignments.create!(user: owner, role: "owner")
    project = company.projects.create!(name: "Album Launch")
    sign_in owner, scope: :user

    get new_usr_company_job_path(company, project_id: project.id)

    assert_response :success
    assert_select "select[name='job[project_id]'] option[selected][value='#{project.id}']"

    assert_difference "project.jobs.count", 1 do
      post usr_company_jobs_path(company), params: {
        job: {
          title: "Lighting Designer",
          description: "Design lighting for the launch.",
          employment_type: "contract",
          workplace_type: "on_site",
          posting_type: "single_role",
          status: "published",
          is_active: true,
          project_id: project.id
        }
      }
    end

    assert_redirected_to usr_project_path(project)
  end
end
