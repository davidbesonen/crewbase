class Usr::ProjectCrewMatrixComponent < ApplicationComponent
  def initialize(overview:, selected_show_id: nil)
    @overview, @project = overview, overview.project
    @selected_show = overview.shows.find { |show| show.id.to_s == selected_show_id.to_s }
  end

  def shows = @selected_show ? [ @selected_show ] : @overview.shows
  def rows = @selected_show ? @overview.rows_for(@selected_show) : @overview.rows
  def names(row) = row.names.presence&.join(", ") || "Open role"
  def coverage_label(row) = row.job.all_shows? ? "Entire run" : (row.job.selected_shows? ? "#{row.show_ids.size} selected shows" : "Dates set separately")
  def status(row) = "#{row.confirmed} confirmed · #{row.tentative} tentative · #{row.open_count} open"
  def show_status(row, show) = "#{row.confirmed_for(show)} confirmed · #{row.open_for(show)} open"
end
