require "test_helper"

class Usr::ProjectPlanningComponentsTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers
  Overview = Data.define(:project, :shows, :rows) do
    def rows_for(show) = rows.select { |row| row.show_ids.include?(show.id) }
  end

  setup do
    @company = Company.new(id: 71, name: "Road Crew")
    @project = Project.new(id: 81, company: @company, name: "Fall Tour", project_type: :multi_show)
    @show = ProjectShow.new(id: 91, project: @project, name: "Opening Night", city: "Austin", starts_on: Date.new(2030, 10, 1))
  end

  test "route entry has labeled city and date fields without asking for a job setup" do
    render_inline Usr::ProjectShowsFormComponent.new(project: @project, rows: [ { "city" => "Austin" } ])
    assert_selector "form[action='#{usr_project_project_shows_path(@project)}']"
    assert_selector "input[name='shows[0][city]'][value='Austin'][required]"
    assert_selector "label[for='stop_0_starts_on']", text: "Show Date"
    assert_selector "input[type='date'][name='shows[0][starts_on]'][required]"
    assert_no_selector "select[name='source']"
    assert_selector "button", text: "Add Another Show"
  end

  test "crew plan distinguishes whole run selected shows and tentative roster plans" do
    render_inline Usr::ProjectCrewPlanFormComponent.new(project: @project, shows: [ @show ], members: [],
      values: { "show_coverage" => "selected_shows", "project_show_ids" => [ @show.id ] })
    assert_selector "select[name='crew_plan[show_coverage]'] option[value='selected_shows'][selected]"
    assert_selector "input[name='crew_plan[project_show_ids][]'][value='91'][checked]"
    assert_text "tentative plan, not a confirmed booking"
    assert_selector "select[name='crew_plan[crew_member_id]'] option[value='']", text: "Leave open — find crew later"
  end

  test "crew matrix shows city coverage and separates tentative and confirmed counts" do
    job = Job.new(id: 101, company: @company, project: @project, title: "Local Stagehand", show_coverage: :selected_shows)
    row = ProjectStaffingOverview::Row.new(job:, names: [ "Alex Local" ], confirmed: 0, tentative: 1,
      needed: 1, show_ids: [ @show.id ], confirmed_show_counts: { @show.id => 0 })
    overview = Overview.new(project: @project, shows: [ @show ], rows: [ row ])
    render_inline Usr::ProjectCrewMatrixComponent.new(overview:)
    assert_selector "[data-crew-show-row='101']", text: /Alex Local/
    assert_selector "[data-crew-show-row='101']", text: /0 confirmed · 1 tentative/
    assert_selector "[data-show-covered='91'][title='0 confirmed · 1 open']"
    assert_selector "th[scope='col']", text: /Austin/
    assert_selector "a[href='#{edit_usr_company_job_path(@company, job)}']", text: "Edit Shows / Role"
    assert_text "Use separate role plans when two people have different cities"
  end

  test "job placement explains the different containers before asking for details" do
    render_inline Usr::JobPlacementComponent.new(company: @company, projects: [ @project ], gigs: [], values: {})
    assert_selector "input[type='radio'][name='placement[kind]'][required]", count: 3
    assert_selector "label[for='placement_kind_project']", text: /Tour \/ Festival Project/
    assert_selector "a[href='#{new_usr_company_project_path(@company)}']", text: "Start A New Tour / Festival Project"
  end
end
