class Usr::ProjectCrewPlanFormComponent < ApplicationComponent
  def initialize(project:, shows:, members:, values:)
    @project, @shows, @members, @values = project, shows, members, values
  end

  def selected_show?(show) = Array(@values["project_show_ids"]).map(&:to_s).include?(show.id.to_s)
end
