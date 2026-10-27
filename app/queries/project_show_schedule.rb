# Shared by every posting updated during a route change. Resolve cities once,
# rather than repeating one location lookup per city for every touring role.
class ProjectShowSchedule
  def initialize(project:)
    @project = project
  end

  def shows = @shows ||= @project.project_shows.chronological.to_a

  def locations_for(selected_shows)
    selected_shows.map do |show|
      key = [ show.city, show.state, show.country ]
      locations_by_address[key] ||= Location.new(city: show.city, state: show.state, country: show.country)
    end.uniq
  end

  private

  def locations_by_address
    @locations_by_address ||= Location.where(city: shows.map(&:city).uniq, address_line_1: [ nil, "" ], address_line_2: [ nil, "" ], zip_code: [ nil, "" ]).to_a.index_by do |location|
      [ location.city, location.state, location.country ]
    end
  end
end
