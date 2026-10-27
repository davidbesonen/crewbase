require "test_helper"

class Usr::JobPlacementsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Post", last_name: "Owner", email: "post-placement@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Placement Co", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @project = @company.projects.create!(name: "Fall Tour", project_type: :multi_show)
    @gig = @company.jobs.create!(title: "Saturday Show", posting_type: :multi_position, status: :draft, workplace_type: :on_site, employment_type: :contract)
    sign_in @owner
  end

  test "post a job explains standalone roles existing gigs and tour projects" do
    get "/usr/companies/#{@company.id}/job_placement/new"
    assert_response :success
    assert_select "input[name='placement[kind]']", count: 3
    assert_select "option[value='#{@project.id}']", text: "Fall Tour"
    assert_select "option[value='#{@gig.id}']", text: "Saturday Show"
    post "/usr/companies/#{@company.id}/job_placement", params: { placement: { kind: "project", project_id: @project.id } }
    assert_redirected_to new_usr_company_job_path(@company, project_id: @project.id)
    post "/usr/companies/#{@company.id}/job_placement", params: { placement: { kind: "gig", job_id: @gig.id } }
    assert_redirected_to usr_job_crew_path(@gig, anchor: "add-crew-position")
    post "/usr/companies/#{@company.id}/job_placement", params: { placement: { kind: "standalone" } }
    assert_redirected_to new_usr_company_job_path(@company)
  end

  test "invalid choices keep context and another company cannot be used" do
    post "/usr/companies/#{@company.id}/job_placement", params: { placement: { kind: "project" } }
    assert_response :unprocessable_entity
    assert_select "[role='alert']", text: /Choose a project/
    @company.company_assignments.destroy_all
    get "/usr/companies/#{@company.id}/job_placement/new"
    assert_response :not_found
  end
end
