class Usr::ProjectShowsComponent < ApplicationComponent
  def initialize(overview:)
    @overview, @project = overview, overview.project
  end

  def coverage(show)
    rows = @overview.rows_for(show)
    return "Staffing not planned yet" if rows.empty?
    "#{rows.sum { |row| row.confirmed_for(show) }} confirmed · #{rows.sum { |row| row.open_for(show) }} open · #{rows.sum(&:tentative)} tentative"
  end

  def posting_path(show) = new_usr_company_job_path(@project.company, project_id: @project.id, project_show_id: show.id, audience: "invite_only")
end
