class Usr::StaffingStartComponent < ApplicationComponent
  Choice = Data.define(:key, :title, :description, :icon)

  def initialize(start:, companies:, projects_path:)
    @start, @companies, @projects_path = start, companies, projects_path
  end

  def error_message = @start.errors.map(&:message).to_sentence

  def choices
    [
      Choice.new(key: "single", title: "Single Gig", icon: "calendar-event",
        description: "One show or one continuous gig. Staff a single role or an entire crew, even if the gig spans several days."),
      Choice.new(key: "multi_show", title: "Tour Or Multi-Show Event", icon: "calendar-range",
        description: "A tour, festival weekend, or a run of separate shows. Start by naming a Project, then add its shows and cities and staff crew across the run.")
    ]
  end
end
