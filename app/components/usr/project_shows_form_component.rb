class Usr::ProjectShowsFormComponent < ApplicationComponent
  Row = Data.define(:index, :values, :editing) do
    def name(field) = editing ? "show[#{field}]" : "shows[#{index}][#{field}]"
    def id(field) = "stop_#{index}_#{field}"
    def show_count = values.fetch("show_count", 1)
    def show_count_choice = values["show_count_choice"].presence || (show_count.to_s.in?(%w[1 2 3]) ? show_count.to_s : "other")
    def custom_show_count? = show_count_choice == "other"
    def show_time_value
      value = values["show_time"]
      value.respond_to?(:strftime) ? value.strftime("%H:%M") : value
    end
  end

  def initialize(project:, rows:, show: nil)
    @project, @show = project, show
    @rows = rows.each_with_index.map { |values, index| Row.new(index:, values:, editing: show.present?) }
  end

  def form_url = @show ? usr_project_project_show_path(@project, @show) : usr_project_project_shows_path(@project)
  def fields = { name: [ "Show Name (Optional)", "Defaults to the city" ], city: [ "City", "Nashville" ], state: [ "State / Region", "TN" ], venue_name: [ "Venue (Optional)", "Search by venue or city" ], country: [ "Country (Optional)", "United States" ] }
end
