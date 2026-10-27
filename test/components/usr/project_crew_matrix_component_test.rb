require "test_helper"

class Usr::ProjectCrewMatrixComponentTest < ViewComponent::TestCase
  self.fixture_table_names = []

  setup do
    company = Company.create!(name: "Column Test Productions", contact_email: "columns@example.com", industries: [ Industry.music_touring! ])
    @project = company.projects.create!(name: "Fall Tour", project_type: :multi_show)
    company.jobs.create!(project: @project, title: "Tour Manager", status: :draft, employment_type: :contract, workplace_type: :on_site)
  end

  test "matching cities and dates use distinct show times" do
    early = show(name: "Lincoln", show_time: "18:00")
    late = show(name: "Lincoln", show_time: "21:00")
    render_matrix
    assert_selector "th[data-crew-show-column='#{early.id}']", text: "6:00 PM local"
    assert_selector "th[data-crew-show-column='#{late.id}']", text: "9:00 PM local"
  end

  test "missing or matching times fall back to show titles" do
    early = show(name: "Acoustic Set", show_time: "19:00")
    late = show(name: "Main Stage", show_time: "19:00")
    render_matrix
    assert_selector "th[data-crew-show-column='#{early.id}']", text: "Acoustic Set"
    assert_selector "th[data-crew-show-column='#{late.id}']", text: "Main Stage"
    late.update!(show_time: nil)
    render_matrix
    assert_selector "th[data-crew-show-column='#{early.id}']", text: "Acoustic Set"
    assert_selector "th[data-crew-show-column='#{late.id}']", text: "Main Stage"
  end

  test "identical default names and missing times get stable show numbers even when filtered" do
    first = show(name: "Lincoln")
    second = show(name: "Lincoln")
    render_matrix
    assert_selector "th[data-crew-show-column='#{first.id}']", text: "Show 1"
    assert_selector "th[data-crew-show-column='#{second.id}']", text: "Show 2"
    render_matrix(selected_show_id: second.id)
    assert_selector "th[data-crew-show-column='#{second.id}']", text: "Show 2"
    assert_no_selector "th[data-crew-show-column='#{first.id}']"
  end

  private

  def show(**attributes)
    @project.project_shows.create!({ city: "Lincoln", state: "NE", starts_on: "2030-11-02" }.merge(attributes))
  end

  def render_matrix(**options)
    @project.jobs.sole.project_shows = @project.project_shows
    render_inline Usr::ProjectCrewMatrixComponent.new(overview: ProjectStaffingOverview.new(project: @project), **options)
  end
end
