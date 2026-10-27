class Usr::ProjectShowsFormComponent < ApplicationComponent
  Row = Data.define(:index, :values, :editing) do
    def name(field) = editing ? "show[#{field}]" : "shows[#{index}][#{field}]"
    def id(field) = "stop_#{index}_#{field}"
  end

  def initialize(project:, rows:, show: nil)
    @project, @show = project, show
    @rows = rows.each_with_index.map { |values, index| Row.new(index:, values:, editing: show.present?) }
  end

  def form_url = @show ? usr_project_project_show_path(@project, @show) : usr_project_project_shows_path(@project)
  def fields = { name: [ "Show / Event Name", "Opening night or main stage" ], city: [ "City", "Nashville" ], state: [ "State / Region", "TN" ], venue_name: [ "Venue (Optional)", "Venue name" ], country: [ "Country (Optional)", "United States" ] }
end
