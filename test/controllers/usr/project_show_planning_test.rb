require "test_helper"

class Usr::ProjectShowPlanningTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  self.fixture_table_names = []

  setup do
    @owner = User.create!(first_name: "Run", last_name: "Owner", email: "show-planning@example.com", password: "password123")
    @owner.profiles.create!(profile_type: "user", completed_at: Time.current)
    @owner.visits.create!
    @company = Company.create!(name: "Run Productions", contact_email: @owner.email, industries: [ Industry.music_touring! ])
    @company.company_assignments.create!(user: @owner, role: "owner")
    @project = @company.projects.create!(name: "Fall Tour", project_type: :multi_show)
    sign_in @owner
  end

  test "tour setup creates a project before asking for shows or crew" do
    get usr_dashboards_path
    assert_select "a", text: "Staff a Tour / Festival"
    get new_usr_company_project_path(@company)
    assert_select "label", text: /Tour, festival or project name/i
    post usr_company_projects_path(@company), params: { next_step: "add_shows", project: { name: "Winter Run" } }
    project = @company.projects.find_by!(name: "Winter Run")
    assert project.multi_show?
    assert_redirected_to new_usr_project_project_show_path(project)
  end

  test "owners can add a route without creating job postings" do
    assert_no_difference "Job.count" do
      post "/usr/projects/#{@project.id}/project_shows", params: { shows: {
        "0" => { name: "Opening Night", city: "Austin", state: "TX", starts_on: "2030-10-01" },
        "1" => { name: "Second Night", city: "Dallas", state: "TX", starts_on: "2030-10-03" }
      } }
    end
    assert_redirected_to usr_project_path(@project)
    assert_equal [ "Austin", "Dallas" ], @project.project_shows.order(:starts_on).pluck(:city)
    get usr_project_path(@project)
    assert_select "[data-project-show]", count: 2
    assert_select "a", text: "Crew By Show"
    assert_select "a", text: "Roles & Postings"
  end

  test "show coverage controls posting dates and locations and survives validation errors" do
    first, second = create_route
    post usr_company_jobs_path(@company), params: { publication_action: "draft", job: job_values.merge(project_show_ids: [ second.id ]) }
    job = @project.jobs.last
    assert job, response.body
    assert_equal [ second.starts_on ], job.work_dates
    assert_equal second.starts_on, job.starts_at.to_date
    assert_equal "Dallas", job.locations.first.city
    assert_equal [ second.id ], job.project_show_ids
    get usr_job_path(job)
    assert_select "[data-job-show-schedule]", text: /Dallas/
    assert_select "[data-job-show-schedule]", text: /Austin/, count: 0

    patch usr_company_job_path(@company, job), params: { job: { show_coverage: "selected_shows", project_show_ids: [] } }
    assert_response :unprocessable_entity
    assert_equal [ second.id ], job.reload.project_show_ids
    assert_select "[role='alert']", text: /Choose at least one show/
    assert_not_includes job.project_show_ids, first.id
  end

  test "whole run roles follow new shows and show changes while selected roles keep their stops" do
    first, second = create_route
    post usr_company_jobs_path(@company), params: { publication_action: "draft", job: job_values.merge(title: "Tour Manager", show_coverage: "all_shows") }
    run_job = @project.jobs.find_by!(title: "Tour Manager")
    post usr_company_jobs_path(@company), params: { publication_action: "draft", job: job_values.merge(project_show_ids: [ first.id ]) }
    local_job = @project.jobs.find_by!(title: "Local Stagehand")
    post "/usr/projects/#{@project.id}/project_shows", params: { shows: { "0" => { name: "Third Night", city: "Denver", starts_on: "2030-10-05" } } }
    assert_redirected_to usr_project_path(@project)
    assert_equal 3, run_job.reload.project_shows.count
    assert_equal [ first.id ], local_job.reload.project_show_ids
    patch "/usr/projects/#{@project.id}/project_shows/#{second.id}", params: { show: { starts_on: "2030-10-04", city: "Fort Worth" } }
    assert_redirected_to usr_project_path(@project)
    assert_equal [ Date.new(2030, 10, 1), Date.new(2030, 10, 4), Date.new(2030, 10, 5) ], run_job.reload.work_dates
    assert_includes run_job.locations.map(&:city), "Fort Worth"
    assert_equal [ first.starts_on ], local_job.reload.work_dates
  end

  test "crew planning supports different cities for each person without confirming bookings" do
    first, second = create_route
    get new_usr_project_crew_plan_path(@project)
    assert_select "h1", text: "Add a Crew Role"
    assert_select "legend", text: "Show Coverage"
    assert_select "input[type='submit'][value='Add Crew Role']"
    member = @company.crew_members.create!(first_name: "Alex", last_name: "Local", phone: "6155550170")
    assert_difference [ "Job.count", "CrewHold.count" ], 1 do
      post "/usr/projects/#{@project.id}/crew_plans", params: { crew_plan: {
        title: "Local Stagehand", crew_member_id: member.id, show_coverage: "selected_shows", project_show_ids: [ second.id ]
      } }
    end
    assert_redirected_to usr_project_path(@project, view: "crew")
    job = @project.jobs.last
    assert job.invite_only?
    assert job.draft?
    assert_equal [ second.id ], job.project_show_ids
    get usr_project_path(@project, view: "crew")
    assert_select "[data-crew-show-row='#{job.id}']", text: /Alex Local/
    assert_select "[data-crew-show-row='#{job.id}'] [data-show-covered='#{second.id}']"
    assert_select "[data-crew-show-row='#{job.id}'] [data-show-covered='#{first.id}']", count: 0
    assert_select "[data-crew-show-row='#{job.id}']", text: /tentative/i
  end

  test "show and crew planning reject other companies and projects" do
    first, = create_route
    other_project = @company.projects.create!(name: "Other Run", project_type: :multi_show)
    foreign_show = other_project.project_shows.create!(name: "Other Show", city: "Boston", starts_on: "2030-10-04")
    assert_no_difference "Job.count" do
      post usr_company_jobs_path(@company), params: { publication_action: "draft", job: job_values.merge(project_show_ids: [ foreign_show.id ]) }
    end
    assert_response :not_found
    sign_in @owner
    patch "/usr/projects/#{other_project.id}/project_shows/#{first.id}", params: { show: { city: "Wrong" } }
    assert_response :not_found
    @company.company_assignments.destroy_all
    sign_in @owner
    get "/usr/projects/#{@project.id}/project_shows/new"
    assert_response :not_found
  end

  test "a changed show does not display an old booking as confirmed for its new date" do
    first, = create_route
    worker = User.create!(first_name: "Booked", last_name: "Crew", email: "show-booked@example.com", password: "password123")
    profile = worker.profiles.create!(profile_type: "user", completed_at: Time.current)
    post usr_company_jobs_path(@company), params: { publication_action: "draft", job: job_values.merge(project_show_ids: [ first.id ]) }
    job = @project.jobs.last
    application = job.job_applications.create!(profile:, status: :accepted)
    application.job_offers.create!(profile:, sender: @owner, role: job.title, status: :accepted,
      starts_at: job.starts_at, ends_at: job.ends_at, work_dates: job.work_dates, rate: 100, currency: "USD", pay_unit: "daily")
    get usr_project_path(@project)
    assert_select "[data-project-show='#{first.id}']", text: /1 confirmed/
    patch "/usr/projects/#{@project.id}/project_shows/#{first.id}", params: { show: { starts_on: "2030-10-02" } }
    follow_redirect!
    assert_select "[data-project-show='#{first.id}']", text: /0 confirmed/
    assert_select "[data-project-show='#{first.id}']", text: /1 open/
  end

  test "invalid route batches are atomic and linked shows cannot be deleted" do
    first, = create_route
    assert_no_difference "ProjectShow.count" do
      post "/usr/projects/#{@project.id}/project_shows", params: { shows: {
        "0" => { name: "Good", city: "Chicago", starts_on: "2030-10-06" },
        "1" => { name: "Missing City", starts_on: "2030-10-07" }
      } }
    end
    assert_response :unprocessable_entity
    assert_select "input[value='Chicago']"
    post usr_company_jobs_path(@company), params: { publication_action: "draft", job: job_values.merge(project_show_ids: [ first.id ]) }
    assert_no_difference "ProjectShow.count" do
      delete "/usr/projects/#{@project.id}/project_shows/#{first.id}"
    end
    assert_redirected_to usr_project_path(@project)
  end

  test "deleting a project preserves its postings and dates without dangling show links" do
    first, = create_route
    post usr_company_jobs_path(@company), params: { publication_action: "draft", job: job_values.merge(project_show_ids: [ first.id ]) }
    job = @project.jobs.last
    assert_difference "Project.count", -1 do
      delete usr_project_path(@project)
    end
    assert_nil job.reload.project_id
    assert job.independent?
    assert_equal [ first.starts_on ], job.work_dates
    assert_empty job.project_show_ids
  end

  test "a 25 city route updates whole run postings in one batch without duplicating jobs" do
    post usr_company_jobs_path(@company), params: { publication_action: "draft", job: job_values.merge(title: "Touring Guitarist", show_coverage: "all_shows") }
    job = @project.jobs.last
    rows = 25.times.to_h do |index|
      [ index.to_s, { name: "Show #{index + 1}", city: "City #{index + 1}", starts_on: (Date.new(2030, 10, 1) + index * 2).iso8601 } ]
    end
    assert_no_difference "Job.count" do
      post "/usr/projects/#{@project.id}/project_shows", params: { shows: rows }
    end
    assert_redirected_to usr_project_path(@project)
    assert_equal 25, @project.project_shows.count
    assert_equal 25, job.reload.work_dates.size
    assert_equal 25, job.locations.count
    get usr_project_path(@project, view: "crew")
    assert_select "[data-crew-show-row='#{job.id}'] [data-show-covered]", count: 25
  end

  test "updating a route shares its location lookups across touring roles" do
    first, second = create_route
    4.times do |index|
      post usr_company_jobs_path(@company), params: { publication_action: "draft", job: job_values.merge(title: "Tour Role #{index}", show_coverage: "all_shows") }
    end
    reads = []
    subscriber = ->(_name, _start, _finish, _id, payload) do
      reads << payload[:sql] if !payload[:cached] && payload[:sql].match?(/SELECT .*FROM "locations"/)
    end
    ActiveSupport::Notifications.subscribed(subscriber, "sql.active_record") do
      patch "/usr/projects/#{@project.id}/project_shows/#{second.id}", params: { show: { city: "Fort Worth" } }
    end
    assert_redirected_to usr_project_path(@project)
    assert_operator reads.size, :<=, 2, "Location reads should be shared across roles when the same route changes"
    assert_equal [ first.starts_on, second.starts_on ], @project.jobs.first.work_dates
  end

  test "show cities never reuse a private street address from an unrelated location" do
    first, = create_route
    Location.create!(city: first.city, state: first.state, country: first.country, address_line_1: "Private home address")
    post usr_company_jobs_path(@company), params: { publication_action: "draft", job: job_values.merge(project_show_ids: [ first.id ]) }
    assert_nil @project.jobs.last.locations.sole.address_line_1
  end

  test "city supplies an optional show name and one day needs no end date" do
    get new_usr_project_project_show_path(@project)
    assert_select "input[name='shows[0][name]'][required]", count: 0
    assert_select "input[name='shows[0][ends_on]'][required]", count: 0
    assert_select "select[name='shows[0][show_count_choice]'] option[value='1'][selected]"
    post usr_project_project_shows_path(@project), params: { shows: { "0" => { city: "Austin", starts_on: "2030-10-01" } } }
    assert_redirected_to usr_project_path(@project)
    show = @project.project_shows.sole
    assert_equal "Austin", show.name
    assert_equal 1, show.show_count
    assert_equal [ Date.new(2030, 10, 1) ], show.work_dates
  end

  test "show counts support presets and custom counts without guessing additional dates" do
    post usr_project_project_shows_path(@project), params: { shows: {
      "0" => { city: "Austin", starts_on: "2030-10-01", show_count_choice: "2", show_count: "1" },
      "1" => { name: "Festival", city: "Dallas", starts_on: "2030-10-03", ends_on: "2030-10-05", show_count_choice: "other", show_count: "5" }
    } }
    assert_redirected_to usr_project_path(@project)
    first, last = @project.project_shows.chronological
    assert_equal 2, first.show_count
    assert_equal 1, first.work_dates.size
    assert_includes first.display_name, "2 shows"
    assert_not_includes first.display_name, "Austin · Austin"
    assert_equal 5, last.show_count
    assert_equal 3, last.work_dates.size
    get usr_project_path(@project)
    assert_select "[data-project-show='#{last.id}']", text: /5 shows/
    assert_select "a", text: "Shows & Cities (7)"
    patch usr_project_project_show_path(@project, first), params: { show: { show_count_choice: "other", show_count: "0" } }
    assert_response :unprocessable_entity
    assert_equal 2, first.reload.show_count
    assert_select "input[name='show[show_count]'][value='0']"
  end

  test "unused show rows with default counts are ignored" do
    post usr_project_project_shows_path(@project), params: { shows: {
      "0" => { city: "Austin", starts_on: "2030-10-01", show_count_choice: "1", show_count: "1" },
      "1" => { city: "", name: "", starts_on: "", show_count_choice: "1", show_count: "1" }
    } }
    assert_redirected_to usr_project_path(@project)
    assert_equal 1, @project.project_shows.count
  end

  test "optional show time saves separately from dates and appears in staffing schedules" do
    get new_usr_project_project_show_path(@project)
    assert_select "input[type='time'][name='shows[0][show_time]']"
    assert_select "input[name='shows[0][show_time]'][required]", count: 0
    post usr_project_project_shows_path(@project), params: { shows: { "0" => { city: "Austin", starts_on: "2030-10-01", show_time: "19:30" } } }
    assert_redirected_to usr_project_path(@project)
    show = @project.project_shows.sole
    assert_equal "19:30", show.show_time.strftime("%H:%M")
    assert_equal [ Date.new(2030, 10, 1) ], show.work_dates
    get usr_project_path(@project)
    assert_select "[data-project-show='#{show.id}']", text: /7:30 PM/
    post usr_company_jobs_path(@company), params: { publication_action: "draft", job: job_values.merge(project_show_ids: [ show.id ]) }
    get usr_job_path(@project.jobs.last)
    assert_select "[data-job-show-schedule]", text: /7:30 PM/
    get edit_usr_project_project_show_path(@project, show)
    assert_select "input[name='show[show_time]'][value='19:30']"
    patch usr_project_project_show_path(@project, show), params: { show: { show_time: "07:05" } }
    assert_redirected_to usr_project_path(@project)
    assert_equal "07:05", show.reload.show_time.strftime("%H:%M")
    assert_equal Date.new(2030, 10, 1), show.starts_on
    patch usr_project_project_show_path(@project, show), params: { show: { show_time: "" } }
    assert_redirected_to usr_project_path(@project)
    assert_nil show.reload.show_time
  end

  test "invalid show times are rejected without saving a partial route" do
    post usr_project_project_shows_path(@project), params: { shows: { "0" => { city: "Austin", starts_on: "2030-10-01", show_time: "not-a-time" } } }
    assert_response :unprocessable_entity
    assert_equal 0, @project.project_shows.count
    assert_select ".alert", text: /Show time/
  end

  private

  def create_route
    [ @project.project_shows.create!(name: "Opening Night", city: "Austin", state: "TX", starts_on: "2030-10-01"),
      @project.project_shows.create!(name: "Second Night", city: "Dallas", state: "TX", starts_on: "2030-10-03") ]
  end

  def job_values
    { title: "Local Stagehand", project_id: @project.id, posting_type: "single_role", employment_type: "contract",
      workplace_type: "on_site", show_coverage: "selected_shows" }
  end
end
