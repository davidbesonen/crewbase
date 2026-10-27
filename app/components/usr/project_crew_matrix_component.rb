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

  def column_details(show)
    group = show_groups.fetch([ show.city.downcase, show.starts_on ])
    details = [ show.starts_on.strftime("%b %-d"), show.show_time_label ]
    if group.size > 1 && !distinct_times?(group)
      title = show.name unless show.name.casecmp?(show.city)
      title_is_unique = title.present? && group.count { |other| other.name.casecmp?(title) } == 1
      number = "Show #{group.index(show) + 1}"
      details << (title_is_unique ? title : [ title, number ].compact_blank.join(" · "))
    end
    details.compact_blank
  end

  private

  def show_groups
    @show_groups ||= @overview.shows.group_by { |show| [ show.city.downcase, show.starts_on ] }
  end

  def distinct_times?(group)
    times = group.map { |show| show.show_time&.strftime("%H:%M") }
    times.none?(&:nil?) && times.uniq.size == group.size
  end
end
